use strict; use warnings;
package Lingy::nREPL;

use Lingy;
use IO::Socket::INET;
use IO::Select;
use Bencode;
use YAML::PP;
use Data::UUID;
use IO::All;
use Cwd;

use XXX;

use constant log_file => Cwd::cwd . '/.nrepl-log';

sub new {
    my ($class, %args) = @_;

    srand;
    my $port = int(rand(10000)) + 40000;

    my $socket = IO::Socket::INET->new(
        LocalPort => $port,
        Proto => 'tcp',
        Listen => SOMAXCONN,
        Reuse => 1
    ) or die "Can't create socket: $IO::Socket::errstr";

    $socket->autoflush;

    my $ypp = YAML::PP->new(
        header => 0,
    );

    my $log = io(log_file);

    my $self = bless {
        port => $port,
        socket => $socket,
        repl => Lingy->new,
        clients => {},
        sessions => {},
        logging => $args{logging},
        verbose => $args{verbose},
        ypp => $ypp,
        log => $log,
    }, $class;

    return $self;
}

#------------------------------------------------------------------------------
# nREPL server op codes handlers:
#------------------------------------------------------------------------------
sub op_eval {
    my ($self) = @_;

    my $result;
    eval {
        $result = $self->{repl}->rep($self->{request}{code});
    };
    $result = $@ if $@;

    $self->send_response({value => $result});

    $self->send_response({status => 'done'});
}

sub op_clone {
    my ($self) = @_;

    my $session_to_clone = exists $self->{request}{session}
        ? $self->{request}{session}
        : 'default';

    my $new_session_id;
    do {
        $new_session_id = Data::UUID->new->create_str();
    } while (exists $self->{sessions}->{$new_session_id});

    my %cloned_session = %{ $self->{sessions}->{$session_to_clone} };
    $self->{sessions}->{$new_session_id} = \%cloned_session;

    $self->send_response({
        'new-session' => $new_session_id,
        status => 'done',
    });
}

sub op_describe {
    my ($self) = @_;

    my %ops = map {($_ => +{})}
        qw(eval clone describe close);

    $self->send_response({
        ops => { %ops },
        status => 'done',
    });
}

sub op_close {
    my ($self) = @_;


    if (my $session_to_close = $self->{request}{session}) {
        if (exists $self->{sessions}{$session_to_close}) {
            delete $self->{sessions}{$session_to_close};
            $self->send_response({status => 'done'});
        } else {
            $self->{error} = "No such session: '$session_to_close'";
            $self->send_response({
                status => 'error',
                error => 'No such session',
            });
        }
    } else {
        $self->{error} = "No session specified to close";
        $self->send_response({
            status => 'error',
            error => 'No session specified',
        });
    }
}

#------------------------------------------------------------------------------
# Starting and stopping server:
#------------------------------------------------------------------------------
sub start {
    my ($self) = @_;

    $self->{sessions}{default} = {};

    my $port = $self->{port};

    io('.nrepl-port')->print($port);

    print "Starting: nrepl://127.0.0.1:$port\n";
    print "Log file: $self->{log}\n";

    $self->log({
        '===' => 'START',
        'url' => "nrepl://127.0.0.1:$port",
    });

    $self->{select} = IO::Select->new($self->{socket});

    $SIG{INT} = sub {
        $self->log({
            '===' => 'INTERUPT',
        });
        $self->stop;
        exit 0;
    };

    return $self;
}

sub run {
    my ($self) = @_;

    my $select = $self->{select};

    my $client = 0;

    while (1) {
        my @ready = $select->can_read;
        foreach my $socket (@ready) {
            delete @{$self}{qw( conn request error )};

            if ($socket == $self->{socket}) {
                my $new_conn = $self->{socket}->accept;
                $self->{clients}->{$new_conn} = ++$client;
                $select->add($new_conn);
                $self->log({
                    '===' => 'CONNECT',
                    client => $client,
                });
            } else {
                my $buffer;
                my $bytes_read = sysread($socket, $buffer, 65535);
                if ($bytes_read > 0) {
                    my $client_id = $self->{clients}->{$socket};
                    my $request = Bencode::bdecode($buffer, 1);
                    my $op = $request->{op};
                    $self->log({
                        '-->'   => ":op $op, :client $client_id",
                        buffer  => "$bytes_read: $buffer",
                        request => $request,
                    });

                    my $handler = "op_$op";
                    if ($self->can($handler)) {
                        @{$self}{qw( conn request )} = (
                            $socket,
                            $request,
                        );
                        $self->$handler;
                    } else {
                        $self->log({
                            '???'  => $op,
                            client => $client_id,
                        });
                    }
                } else {
                    # Connection closed by client
                    my $client_id = $self->{clients}->{$socket};
                    delete $self->{clients}->{$socket};
                    $select->remove($socket);
                    close($socket);
                    $self->log({
                        '===' => 'CLOSED',
                        client => $client,
                    });
                }
            }
        }
    }
}

sub stop {
    my ($self) = @_;

    if (!defined $self->{select}) {
        return;
    }

    my $port = $self->{port};

    if (-e '.nrepl-port') {
        unlink '.nrepl-port'
            or warn "Could not remove .nrepl-port file: $!";
    }

    $self->log({
        '===' => 'STOP',
        'url' => "nrepl://127.0.0.1:$port",
    });

    foreach my $client ($self->{select}->handles) {
        if ($client != $self->{socket}) {
            $self->{select}->remove($client);
            shutdown($client, 2)
                or warn "Couldn't properly shut down a client connection: $!";
            close $client
                or warn "Couldn't close a client connection: $!";
        }
    }

    $self->{select}->remove($self->{socket});

    if ($self->{socket}) {
        close $self->{socket}
            or warn "Couldn't close the server socket: $!";
        $self->{socket} = undef;
    }

    $self->{select} = undef;
}

sub DESTROY {
    my ($self) = @_;
    $self->stop;
}

#------------------------------------------------------------------------------
# nREPL server response methods:
#------------------------------------------------------------------------------

sub send_response {
    my ($self, $data) = @_;
    my ($conn, $request) =
        @{$self}{qw(conn request)};

    my $response = {
        id => $request->{id},
        $request->{session} ? (session => $request->{session}) : (),
        %$data,
    };

    print $conn Bencode::bencode($response);

    $self->log({
        '<--'    => ":op $request->{op}, :client $self->{clients}{$conn}",
        response => $response,
    });

    return;
}

#------------------------------------------------------------------------------
# Logging
#------------------------------------------------------------------------------

sub log {
    my ($self, $data) = @_;
    $data->{error} = $self->{error} if $self->{error};
    my $yaml = $self->{ypp}->dump_string($data);
    $self->{log}->print($yaml . "\n")->autoflush;
}

#------------------------------------------------------------------------------
# Hot patch Bencode to encode numbers as strings
#------------------------------------------------------------------------------
{
    package Bencode;
    no warnings 'redefine';
    our ( $DEBUG, $do_lenient_decode, $max_depth, $undef_encoding );
    sub _bencode {
        map
        +( ( not defined     ) ? ( $undef_encoding or croak 'unhandled data type' )
        #:  ( not ref         ) ? ( m/\A (?: 0 | -? [1-9] \d* ) \z/x ? 'i' . $_ . 'e' : length . ':' . $_ )
        :  ( not ref ) ? length . ':' . $_
        :  ( 'SCALAR' eq ref ) ? ( length $$_ ) . ':' . $$_ # escape hatch -- use this to avoid num/str heuristics
        :  (  'ARRAY' eq ref ) ? 'l' . ( join '', _bencode @$_ ) . 'e'
        :  (   'HASH' eq ref ) ? 'd' . do { my @k = sort keys %$_; join '', map +( length $k[0] ) . ':' . ( shift @k ) . $_, _bencode @$_{ @k } } . 'e'
        :  croak 'unhandled data type'
        ), @_
    }
}

1;

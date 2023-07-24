use strict; use warnings;
package Lingy::nREPL;

use Lingy;
use Lingy::Common;
use IO::Socket::INET;
use IO::Select;
use Bencode;
use YAML::PP;
use Data::UUID;
use IO::All;
use Cwd;

use XXX;

use constant default_log_file => '.nrepl-log';
use constant port_file => $ENV{LINGY_NREPL_PORT_FILE} // '.nrepl-port';

sub new {
    my ($class, %args) = @_;

    srand;
    my $port = int(rand(10000)) + 40000;

    my $socket = IO::Socket::INET->new(
        LocalPort => $port,
        Proto => 'tcp',
        Listen => SOMAXCONN,
        Reuse => 1,
    ) or die "Can't create socket: $IO::Socket::errstr";

    $socket->autoflush;

    my $log;
    if (my $log_file = $ENV{LINGY_NREPL_LOG}) {
        $log_file = default_log_file if $log_file eq '1';
        $log = io($log_file);
        $log->absolute unless $log->is_stdio;
    }

    my $self = bless {
        port => $port,
        socket => $socket,
        runtime => Lingy->new,
        clients => {},
        sessions => {},
        yaml => YAML::PP->new(header => 0),
        log => $log,
    }, $class;

    return $self;
}

#------------------------------------------------------------------------------
# nREPL server op codes handlers:
#------------------------------------------------------------------------------
sub op_eval {
    my ($self) = @_;

    if (my $file = $self->{request}{file}) {
        RT->env->set('*file*', STRING->new($file));
    }

    eval {
        local *STDOUT;
        tie *STDOUT, 'StreamedOutput',
            sub { $self->send_response(@_) },
            'out';

        local *STDERR;
        tie *STDERR, 'StreamedOutput',
            sub { $self->send_response(@_) },
            'err';

        my $code = $self->{request}->{code};
        if (my @results = $self->{runtime}->reps($code)) {
            $self->send_response({
                value => $results[-1],
                ns => RT->current_ns_name
            });
        }
    };
    $self->send_response({err => $@}) if $@;

    $self->send_response({status => 'done'});
}

sub op_clone {
    my ($self) = @_;

    my $session_to_clone = exists $self->{request}{session}
        ? $self->{request}{session}
        : 'default';

    my $session_id = Data::UUID->new->create_str();

    my %cloned_session = %{ $self->{sessions}->{$session_to_clone} };
    $self->{sessions}->{$session_id} = \%cloned_session;

    $self->send_response({
        'new-session' => $session_id,
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


    my $session_to_close = $self->{request}{session} or
        return $self->send_response({
            status => 'error',
            error => "No session specified to close",
        });

    $self->{sessions}{$session_to_close} or
        return $self->send_response({
            status => 'error',
            error => "No such session: '$session_to_close'",
        });

    delete $self->{sessions}{$session_to_close};

    $self->send_response({status => 'done'});
}

#------------------------------------------------------------------------------
# Starting and stopping server:
#------------------------------------------------------------------------------
sub start {
    my ($self) = @_;

    $self->{sessions}{default} = {};

    my $port = $self->{port};

    io(port_file)->print($port);

    print "nREPL server started on port $port " .
          "on host 127.0.0.1 - nrepl://127.0.0.1:$port\n";

    if (my $log = $self->{log}) {
        print "Log file: $log\n"
            unless $log->is_stdio;
    }

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
        foreach my $socket ($select->can_read(0.01)) {
            delete @{$self}{qw( conn request )};

            if ($socket == $self->{socket}) {
                my $connection = $self->{socket}->accept;
                $self->{clients}->{$connection} = ++$client;
                $select->add($connection);
                $self->log({
                    '===' => 'CONNECT',
                    client => $client,
                });
                next;
            }

            my ($request, $buffer, $length) =
                $self->next_request($socket, $client)
                    or next;

            my $op = $request->{op};
            my $client_id = $self->{clients}->{$socket};

            $self->log({
                '-->'   => ":op $op, :client $client_id",
                buffer  => "$length: $buffer",
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
                    error  => "Unsupported op: '$op'",
                });
            }
        }
    }
}

sub stop {
    my ($self) = @_;

    return unless defined $self->{select};

    if (-e port_file) {
        unlink port_file
            or warn "Could not unlink '${\ port_file}' file: $!";
    }

    $self->log({
        '===' => 'STOP',
        'url' => "nrepl://127.0.0.1:$self->{port}",
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

sub next_request {
    my ($self, $socket, $client) = @_;
    my $buffer;
    my $length = sysread($socket, $buffer, 65535)
        or return $self->close_socket($socket, $client);
    my $request;
    eval {
        $request = Bencode::bdecode($buffer, 1);
    };
    die "Error decoding request buffer:\n$buffer\n$@" if $@;
    return ($request, $buffer, $length);
}

sub close_socket {
    my ($self, $socket, $client) = @_;
    # Connection closed by client
    my $client_id = $self->{clients}->{$socket};
    delete $self->{clients}->{$socket};
    $self->{select}->remove($socket);
    close($socket);
    $self->log({
        '===' => 'CLOSED',
        client => $client,
    });
    return;
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
    my ( $self, $data ) = @_;
    my $log = $self->{log} or return;
    my $yaml = $self->{yaml}->dump_string($data);
    $log->print( $yaml . "\n" );
    $log->autoflush unless $log->is_stdio;
}

#------------------------------------------------------------------------------
# Tied class to capture stdio during Lingy evals
#------------------------------------------------------------------------------
{
    package StreamedOutput;

    sub TIEHANDLE {
        my ($class, $send_response, $output_type) = @_;
        bless {
            send_response => $send_response,
            output_type => $output_type,
        }, $class;
    }

    sub PRINT {
        my ( $self, @args ) = @_;
        my $output_type = $self->{output_type} // 'out';
        $self->{send_response}->({$output_type => join('', @args)});
    }

    sub PRINTF {
        my ( $self, $format, @args ) = @_;
        $self->PRINT(sprintf $format, @args);
    }
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

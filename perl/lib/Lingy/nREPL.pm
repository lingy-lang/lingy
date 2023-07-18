use strict; use warnings;
package Lingy::nREPL;

use IO::Socket::INET;
use IO::Select;
use Bencode;
use Data::Dumper;

use XXX;

srand;

sub new {
    my ($class, %args) = @_;

    my $port = int(rand(10000)) + 40000;

    my $socket = IO::Socket::INET->new(
        LocalPort => $port,
        Proto => 'tcp',
        Listen => SOMAXCONN,
        Reuse => 1
    ) or die "Can't create socket: $IO::Socket::errstr";

    $socket->autoflush;

    my $self = bless {
        port => $port,
        socket => $socket,
        clients => {},
        'nrepl-message-logging' => $args{'nrepl-message-logging'} // 0,
        'verbose' => $args{'verbose'} // 0,
    }, $class;

    return $self;
}

sub debug_print {
    my ($self, $message, $direction) = @_;
    if (defined $direction && $self->{'nrepl-message-logging'}) {
        print "$direction\n$message";
    } elsif ($self->{'verbose'}) {
        print "$message";
    }
}

sub prepare_response {
    my ($received, $additional_fields) = @_;

    my %response = (
        'id' => "$received->{'id'}",
    );

    if (exists $received->{'session'}) {
        $response{'session'} = $received->{'session'};
    }

    return { %response, %$additional_fields };
}

sub send_response {
    my ($self, $conn, $response) = @_;
    print $conn Bencode::bencode($response);
    $self->debug_print(Dumper($response), "--> sent, client $self->{clients}->{$conn}");
}

my %op_handlers = (
    'eval' => sub {
        my ($self, $conn, $received) = @_;
        my $response = prepare_response($received, {'value' => 'foo'});
        $self->send_response($conn, $response);
        my $done = prepare_response($received, {'status' => 'done'});
        $self->send_response($conn, $done);
    },
    'clone' => sub {
        my ($self, $conn, $received) = @_;
        my $session = 'a-new-session';
        $self->debug_print("Cloning... new-session: '$session'\n");
        my $response = prepare_response($received, {'new-session' => $session, 'status' => 'done'});
        $self->send_response($conn, $response);
    },
    'describe' => sub {
        my ($self, $conn, $received) = @_;
        $self->debug_print("Describe...\n");
        my $response = prepare_response($received, {'ops' => {'eval' => {}, 'clone' => {}, 'describe' => {}, 'close' => {}}, 'status' => 'done'});
        $self->send_response($conn, $response);
    },
    'close' => sub {
        my ($self, $conn, $received) = @_;
        $self->debug_print("TBD: Close session...\n");
    }
);

sub start {
    my ($self) = @_;

    my $port = $self->{port};

    open(my $fh, '>', '.nrepl-port');
    print $fh $port;
    close($fh);

    print "Starting nrepl://127.0.0.1:$port\n";

    my $select = IO::Select->new($self->{socket});

    my $client = 0;

    while (1) {
        my @ready = $select->can_read;
        foreach my $socket (@ready) {
            if ($socket == $self->{socket}) {
                my $new_conn = $self->{socket}->accept;
                $self->{clients}->{$new_conn} = ++$client;
                $select->add($new_conn);
                $self->debug_print("Accepted a new connection, client id: $client\n");
            } else {
                my $buffer = '';
                my $bytes_read = sysread($socket, $buffer, 65535);
                if ($bytes_read) {
                    my $client_id = $self->{clients}->{$socket};
                    $self->debug_print("Client $client_id: Read $bytes_read bytes\n");
                    $self->debug_print("Client $client_id: Received: $buffer\n");
                    $self->debug_print("Client $client_id: Decoding...\n");
                    my $received = Bencode::bdecode($buffer, 1);
                    $buffer = '';
                    $self->debug_print(Dumper($received), "<-- received, client $client_id");
                    if (exists $op_handlers{$received->{'op'}}) {
                        $op_handlers{$received->{'op'}}->($self, $socket, $received, $client_id);
                    } else {
                        $self->debug_print("Client $client_id: Unknown op: " . $received->{'op'} . "\n");
                    }
                } else {
                    # Connection closed by client
                    my $client_id = $self->{clients}->{"$socket"};
                    $self->debug_print("Client $client_id: Connection closed\n");
                    delete $self->{clients}->{$socket};
                    $select->remove($socket);
                    close($socket);
                }
            }
        }
    }
}

sub stop {
    my ($self) = @_;

    my $port = $self->{port};

    if (-e '.nrepl-port') {
        unlink '.nrepl-port' or warn "Could not remove .nrepl-port file: $!";
    }

    print "Stopping nrepl://127.0.0.1:$port\n";

    $self->{socket}->shutdown
        or die "$!";
}

sub DESTROY {
    my ($self) = @_;
    $self->stop;
}

1;

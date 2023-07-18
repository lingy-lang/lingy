use strict; use warnings;
package Lingy::nREPL;

use IO::Socket::INET;
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
    $self->debug_print(Dumper($response), '--> sent');
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

    print "Starting nrepl://127.0.0.1:$port\n";

    while (my $conn = $self->{socket}->accept) {
        $self->debug_print("Accepted a new connection\n");
        my $buffer = '';
        while (my $bytes_read = sysread($conn, $buffer, 65535)) {
            $self->debug_print("Read $bytes_read bytes\n");
            $self->debug_print("Received: $buffer\n");
            $self->debug_print("Decoding...\n");
            my $received = Bencode::bdecode($buffer, 1);
            $buffer = '';
            $self->debug_print(Dumper($received), 'received');

            if (exists $op_handlers{$received->{'op'}}) {
                $op_handlers{$received->{'op'}}->($self, $conn, $received);
            } else {
                $self->debug_print("Unknown op: " . $received->{'op'} . "\n");
            }
        }
    }
}

sub stop {
    my ($self) = @_;

    my $port = $self->{port};

    print "Stopping nrepl://127.0.0.1:$port\n";

    $self->{socket}->shutdown
        or die "$!";
}

sub DESTROY {
    my ($self) = @_;
    $self->stop;
}

1;

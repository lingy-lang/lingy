use strict; use warnings;
package Lingy::nREPL;

use IO::Socket::INET;
use Bencode;
use Data::Dumper;

use XXX;

srand;

sub new {
    my ($class) = @_;

    my $port = int(rand(10000)) + 40000;

    my $socket = IO::Socket::INET->new(
        LocalPort => $port,
        Proto => 'tcp',
        Listen => SOMAXCONN,
        Reuse => 1
    ) or die "Can't create socket: $IO::Socket::errstr";

    $socket->autoflush;

    bless {
        port => $port,
        socket => $socket,
    }, $class;
}

sub start {
    my ($self) = @_;

    my $port = $self->{port};

    print "Starting nrepl://127.0.0.1:$port\n";

    CONN:
    while (my $conn = $self->{socket}->accept) {
        print "Accepted a new connection\n";
        my $buffer = '';
        while (my $bytes_read = sysread($conn, $buffer, 65535)) {
            print "Read $bytes_read bytes\n";
            print "Buffer: $buffer\n";
            print "Decoding...\n";
            my $received = Bencode::bdecode($buffer, 1);
            $buffer = '';
            print ref($received) . "\n";
            print Dumper($received);
            if ($received->{'op'} eq 'eval') {
                my $send = {
                    'session' => $received->{'session'},
                    'id' => "$received->{'id'}",
                    'value' => 'foo'
                };
                my $encoded = Bencode::bencode($send);
                print $conn Bencode::bencode($send);
                my $done = {
                    'session' => $received->{'session'},
                    'id' => "$received->{'id'}",
                    'status' => 'done',
                };
                print $conn Bencode::bencode($done);
            } elsif ($received->{'op'} eq 'clone') {
                print "Cloning...\n";
                my $session = 'foo';
                my $send = {
                    'id' => "$received->{'id'}",
                    'new-session' => $session
                };
                my $encoded = Bencode::bencode($send);
                print $conn Bencode::bencode($send);
                my $done = {
                    'session' => $session,
                    'id' => "$received->{'id'}",
                    'status' => 'done',
                };
                print $conn Bencode::bencode($done);
                print "Done cloning, new-session: '$session'\n";
            } elsif ($received->{'op'} eq 'close') {
                close($conn);
                last CONN;
            } else {
                print "Unknown op: " . $received->{'op'} . "\n";
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

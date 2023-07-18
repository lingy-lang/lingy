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
    my ($conn, $response) = @_;
    print $conn Bencode::bencode($response);
}

sub start {
    my ($self) = @_;

    my $port = $self->{port};

    print "Starting nrepl://127.0.0.1:$port\n";

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
                my $response = prepare_response($received, {'value' => 'foo'});
                send_response($conn, $response);
                my $done = prepare_response($received, {'status' => 'done'});
                send_response($conn, $done);
            } elsif ($received->{'op'} eq 'clone') {
                my $session = 'a-new-session';
                print "Cloning... new-session: '$session'\n";
                my $response = prepare_response($received, {'new-session' => $session, 'status' => 'done'});
                send_response($conn, $response);
            } elsif ($received->{'op'} eq 'describe') {
                print "Describe...\n";
                my $response = prepare_response($received, {'ops' => {'eval' => {}, 'clone' => {}, 'describe' => {}, 'close' => {}}, 'status' => 'done'});
                send_response($conn, $response);
            } elsif ($received->{'op'} eq 'close') {
                print "TBD: Close session...\n";
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

{
    package Bencode;
    no warnings 'redefine';
    our ( $DEBUG, $do_lenient_decode, $max_depth, $undef_encoding );
    sub _bencode {
        map
        +( ( not defined     ) ? ( $undef_encoding or croak 'unhandled data type' )
        #:  ( not ref         ) ? ( m/\A (?: 0 | -? [1-9] \d* ) \z/x ? 'i' . $_ . 'e' : length . ':' . $_ )
        # TODO: This will treat all non-refs as strings, which might not be what we want.
        :  ( not ref ) ? length . ':' . $_
        :  ( 'SCALAR' eq ref ) ? ( length $$_ ) . ':' . $$_ # escape hatch -- use this to avoid num/str heuristics
        :  (  'ARRAY' eq ref ) ? 'l' . ( join '', _bencode @$_ ) . 'e'
        :  (   'HASH' eq ref ) ? 'd' . do { my @k = sort keys %$_; join '', map +( length $k[0] ) . ':' . ( shift @k ) . $_, _bencode @$_{ @k } } . 'e'
        :  croak 'unhandled data type'
        ), @_
    }
}

1;

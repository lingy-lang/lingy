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
            $self->debug_print(Dumper($received), '<-- received');
            if ($received->{'op'} eq 'eval') {
                my $response = prepare_response($received, {'value' => 'foo'});
                $self->send_response($conn, $response);
                my $done = prepare_response($received, {'status' => 'done'});
                $self->send_response($conn, $done);
            } elsif ($received->{'op'} eq 'clone') {
                my $session = 'a-new-session';
                $self->debug_print("Cloning... new-session: '$session'\n");
                my $response = prepare_response($received, {'new-session' => $session, 'status' => 'done'});
                $self->send_response($conn, $response);
            } elsif ($received->{'op'} eq 'describe') {
                $self->debug_print("Describe...\n");
                my $response = prepare_response($received, {'ops' => {'eval' => {}, 'clone' => {}, 'describe' => {}, 'close' => {}}, 'status' => 'done'});
                $self->send_response($conn, $response);
            } elsif ($received->{'op'} eq 'close') {
                $self->debug_print("TBD: Close session...\n");
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

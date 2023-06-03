use strict; use warnings;
package Foo::Class;

use XXX;

# 'new' makes this a class
sub new {
    my $class = shift;
    bless {@_}, $class;
}

use constant foo => 42;

sub bar {
    $_[0]->{bar} = $_[1] if @_ > 1;
    return $_[0]->{bar};
}

sub add {
    my ($self, $x, $y) = @_;
    $x + $y;
}

1;

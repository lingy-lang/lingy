use strict; use warnings;
package Foo::Class;

use XXX;

# 'new' makes this a class
sub new {
    my $class = shift;
    bless {@_}, $class;
}

use constant foo => 42;
# sub foo {
#     $_[0]->{foo} = $_[1] if @_ > 1;
#     return $_[0]->{foo};
# }

sub bar {
    $_[0]->{bar} = $_[1] if @_ > 1;
    return $_[0]->{bar};
}

1;

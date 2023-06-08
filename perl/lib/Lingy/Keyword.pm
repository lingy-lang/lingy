use strict; use warnings;
package Lingy::Keyword;

use base 'Lingy::ScalarClass';

use overload cmp => \&comp_pair;

sub new {
    my ($class, $scalar) = @_;
    $scalar =~ s/^://;
    $scalar = ":$scalar";
    bless \$scalar, $class;
}

1;

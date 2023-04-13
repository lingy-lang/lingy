use strict; use warnings;
package Lingy::Lang::Keyword;

use base 'Lingy::Lang::ScalarClass';

sub new {
    my ($class, $scalar) = @_;
    $scalar =~ s/^://;
    $scalar = ":$scalar";
    bless \$scalar, $class;
}

1;

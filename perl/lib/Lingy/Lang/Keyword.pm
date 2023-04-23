use strict; use warnings;
package Lingy::Lang::Keyword;

use base 'Lingy::Lang::ScalarClass';
use Lingy::Common;

use overload cmp => \&comp_pair;

sub new {
    my ($class, $scalar) = @_;
    $scalar =~ s/^://;
    $scalar = ":$scalar";
    bless \$scalar, $class;
}

1;

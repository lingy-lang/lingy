use strict; use warnings;
package Lingy::Keyword;

use Lingy::Common;
use base SCALARTYPE;

use overload cmp => \&comp_pair;

sub new {
    my ($class, $scalar) = @_;
    $scalar =~ s/^://;
    $scalar = ":$scalar";
    bless \$scalar, $class;
}

1;

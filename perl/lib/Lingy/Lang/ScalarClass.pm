use strict; use warnings;
package Lingy::Lang::ScalarClass;

use base 'Lingy::Lang::Class';

use overload '""' => sub { ${$_[0]} };
use overload cmp => sub { "$_[0]" cmp "$_[1]" };

sub new {
    my ($class, $scalar) = @_;
    bless \$scalar, $class;
}

1;

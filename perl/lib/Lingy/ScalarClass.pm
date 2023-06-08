use strict; use warnings;
package Lingy::ScalarClass;

use base 'Lingy::Class';

use overload '""' => sub { ${$_[0]} };
use overload cmp => sub { "$_[0]" cmp "$_[1]" };

sub new {
    my ($class, $scalar) = @_;
    bless \$scalar, $class;
}

sub unbox {
    ${$_[0]}
}

1;

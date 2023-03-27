package Lingy::Base::Scalar;

use overload '""' => sub { ${$_[0]} };
use overload cmp => sub { "$_[0]" cmp "$_[1]" };

sub new {
    my ($class, $scalar) = @_;
    bless \$scalar, $class;
}

1;

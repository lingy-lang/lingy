package Lingy::Lang::BaseScalar;

use base 'Lingy::Lang::Base';

use overload '""' => sub { ${$_[0]} };
use overload cmp => sub { "$_[0]" cmp "$_[1]" };

sub new {
    my ($class, $scalar) = @_;
    bless \$scalar, $class;
}

1;

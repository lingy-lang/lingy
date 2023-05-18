use strict; use warnings;
package Lingy::Lang::ScalarClass;

use Lingy::Common;
use base CLASS;

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

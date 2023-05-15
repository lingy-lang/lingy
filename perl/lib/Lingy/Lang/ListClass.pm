use strict; use warnings;
package Lingy::Lang::ListClass;

use Lingy::Common;
use base CLASS;

sub new {
    my ($class, $list) = @_;
    bless $list, $class;
}

sub clone { ref($_[0])->new([@{$_[0]}]) }

1;

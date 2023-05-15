use strict; use warnings;
package Lingy::Lang::Vector;

use Lingy::Common;
use base LISTTYPE;

use overload cmp => \&comp_pair;

sub _to_seq {
    my ($list) = @_;
    @$list ? list([@$list]) : nil;
}

1;

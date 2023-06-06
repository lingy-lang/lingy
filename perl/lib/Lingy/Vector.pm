use strict; use warnings;
package Lingy::Vector;

use Lingy::Common;
use base LISTTYPE, SEQUENTIAL;

use overload cmp => \&comp_pair;

sub _to_seq {
    my ($list) = @_;
    @$list ? list([@$list]) : nil;
}

1;

use strict; use warnings;
package Lingy::Lang::List;

use Lingy::Common;
use base LISTTYPE;

sub _to_seq {
    my ($list) = @_;
    @$list ? $list : nil;
}

1;

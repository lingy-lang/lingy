use strict; use warnings;
package Lingy::List;

use Lingy::Common;
use Lingy::Sequential;
use base 'Lingy::ListClass', 'Lingy::Sequential';

sub _to_seq {
    my ($list) = @_;
    @$list ? $list : nil;
}

1;

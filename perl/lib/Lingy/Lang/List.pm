use strict; use warnings;
package Lingy::Lang::List;

use base 'Lingy::Lang::ListClass';
use Lingy::Common;

sub _to_seq {
    my ($list) = @_;
    @$list ? $list : nil;
}

1;

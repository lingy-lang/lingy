use strict; use warnings;
package Lingy::List;

use Lingy::Common;
use Lingy::Sequential;
use base 'Lingy::ListClass', 'Lingy::Sequential';

my $EMPTY = Lingy::List->new([]);
sub EMPTY { $EMPTY }

sub _to_seq {
    my ($list) = @_;
    @$list ? $list : nil;
}

1;

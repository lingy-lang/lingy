use strict; use warnings;
package Lingy::Lang::Nil;

use base 'Lingy::Lang::ScalarClass';
use Lingy::Common;

{
    package Lingy::Common;
    my ($n);
    ($n) = (1);
    my $nil = bless \$n, 'Lingy::Lang::Nil';
    sub nil { $nil }
}

sub _to_seq {
    nil
}

1;

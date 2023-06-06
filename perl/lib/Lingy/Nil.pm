use strict; use warnings;
package Lingy::Nil;

use Lingy::Common;
use base SCALARTYPE;

{
    package Lingy::Common;
    my ($n);
    ($n) = (1);
    my $nil = bless \$n, NIL;
    sub nil { $nil }
}

sub _to_seq {
    nil
}

1;

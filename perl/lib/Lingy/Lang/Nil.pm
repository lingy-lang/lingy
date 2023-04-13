use strict; use warnings;
package Lingy::Lang::Nil;

use base 'Lingy::Lang::ScalarClass';

{
    package Lingy::Common;
    my ($n);
    ($n) = (1);
    my $nil = bless \$n, 'Lingy::Lang::Nil';
    sub nil { $nil }
}

1;

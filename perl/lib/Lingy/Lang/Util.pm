use strict; use warnings;
package Lingy::Lang::Util;

use Lingy::Common;

sub identical {
    boolean(refaddr($_[0]) == refaddr($_[1]));
}

1;

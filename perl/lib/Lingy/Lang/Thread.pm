use strict; use warnings;
package Lingy::Lang::Thread;

use Lingy::Common;

use Time::HiRes qw(usleep);

sub sleep {
    usleep $_[0] * 1000;
    nil;
}

1;

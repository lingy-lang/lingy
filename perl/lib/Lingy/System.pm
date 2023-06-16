use strict; use warnings;
package Lingy::System;

use Lingy::Common;

use Time::HiRes qw(gettimeofday);

sub nanoTime {
    my ($s, $m) = gettimeofday;
    NUMBER->new(1000 * (1000000 * $s + $m));
}

1;

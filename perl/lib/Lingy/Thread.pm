use strict; use warnings;
package Lingy::Thread;

use base 'Lingy::Class';

use Lingy::Common;

use Time::HiRes qw(usleep);

sub sleep {
    usleep $_[1] * 1000;
    nil;
}

1;

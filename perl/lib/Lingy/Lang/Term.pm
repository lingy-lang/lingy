use strict; use warnings;
package Lingy::Lang::Term;

use Lingy::Common;

sub clear {
    print "\x1b[2J\x1b[H";
    nil;
}

1;

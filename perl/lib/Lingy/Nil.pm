use strict; use warnings;
package Lingy::Nil;

use Lingy::Common;
use base 'Lingy::ScalarClass';

sub _to_seq {
    nil;
}

1;

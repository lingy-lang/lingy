use strict; use warnings;
package Lingy::LazySeq;

use Lingy::Common;

use base 'Lingy::Class';

sub new {
    my ($class, $fn) = @_;
    bless {
        fn => $fn,
    }, $class;
}

1;

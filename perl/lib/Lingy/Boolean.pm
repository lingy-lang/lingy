use strict; use warnings;
package Lingy::Boolean;

use Lingy::Common;
use base 'Lingy::ScalarClass';

sub new {
    my ($class, $scalar) = @_;
    my $type = ref($scalar);
    (not $type) ? $scalar ? true : false :
    $type eq NIL ? false :
    $type eq BOOLEAN ? $scalar :
    true;
}

1;

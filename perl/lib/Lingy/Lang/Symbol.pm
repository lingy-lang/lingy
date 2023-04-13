use strict; use warnings;
package Lingy::Lang::Symbol;

use base 'Lingy::Lang::ScalarClass';
use Lingy::Common;

sub intern {
    $Lingy::Eval::ENV->set($_[0], nil);
    symbol($_[0]);
}

1;

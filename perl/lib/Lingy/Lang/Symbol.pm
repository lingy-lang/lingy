use strict; use warnings;
package Lingy::Lang::Symbol;

use Lingy::Common;
use base SCALARTYPE;

use overload cmp => \&comp_pair;

sub intern {
    $Lingy::Eval::ENV->set($_[0], nil);
    symbol($_[0]);
}

1;

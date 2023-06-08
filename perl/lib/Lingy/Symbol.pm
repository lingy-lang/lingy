use strict; use warnings;
package Lingy::Symbol;

use Lingy::Common;
use Lingy::Evaluator;
use base 'Lingy::ScalarClass';

use overload cmp => \&comp_pair;

sub intern {
    $Lingy::Evaluator::ENV->set($_[0], nil);
    symbol($_[0]);
}

1;

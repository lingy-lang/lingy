package Lingy::Lang::Symbol;

use Lingy::Lang::Base 'Scalar';

sub intern {
    $Lingy::Eval::ENV->set($_[0], nil);
    symbol($_[0]);
}

1;

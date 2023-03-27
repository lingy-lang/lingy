package Lingy::Lang::Symbol;

use Lingy::Base 'Scalar';

use constant lingy_class => 'host.lang.Symbol';

sub intern {
    $Lingy::Eval::ENV->set($_[0], nil);
    symbol($_[0]);
}

1;

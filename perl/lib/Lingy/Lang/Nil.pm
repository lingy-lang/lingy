package Lingy::Lang::Nil;

use Lingy::Base 'Scalar';

use constant lingy_class => 'host.lang.Nil';

{
    package Lingy::Common;
    my ($n);
    ($n) = (1);
    my $nil = bless \$n, 'Lingy::Lang::Nil';
    sub nil { $nil }
}

1;

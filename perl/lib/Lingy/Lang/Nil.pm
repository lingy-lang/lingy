package Lingy::Lang::Nil;

use Lingy::Lang::Base 'Scalar';

{
    package Lingy::Common;
    my ($n);
    ($n) = (1);
    my $nil = bless \$n, 'Lingy::Lang::Nil';
    sub nil { $nil }
}

1;

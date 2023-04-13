use strict; use warnings;
package Lingy::Lang::Boolean;

use base 'Lingy::Lang::ScalarClass';

{
    package Lingy::Common;
    my ($t, $f);
    ($t, $f) = (1, 0);
    my $true = bless \$t, 'Lingy::Lang::Boolean';
    my $false = bless \$f, 'Lingy::Lang::Boolean';
    sub true { $true }
    sub false { $false }
}

sub new {
    my ($class, $scalar) = @_;
    my $type = ref($scalar);
    (not $type) ? $scalar ? Lingy::Common::true() : Lingy::Common::false() :
    $type eq 'Lingy::Lang::Nil' ? Lingy::Common::false :
    $type eq 'Lingy::Lang::Boolean' ? $scalar :
    Lingy::Common::true();
}

1;

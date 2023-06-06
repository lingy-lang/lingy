use strict; use warnings;
package Lingy::Boolean;

use Lingy::Common;
use base SCALARTYPE;

{
    package Lingy::Common;
    my ($t, $f);
    ($t, $f) = (1, 0);
    my $true = bless \$t, BOOLEAN;
    my $false = bless \$f, BOOLEAN;
    sub true { $true }
    sub false { $false }
}

sub new {
    my ($class, $scalar) = @_;
    my $type = ref($scalar);
    (not $type) ? $scalar ? Lingy::Common::true() : Lingy::Common::false() :
    $type eq NIL ? Lingy::Common::false :
    $type eq BOOLEAN ? $scalar :
    Lingy::Common::true();
}

1;

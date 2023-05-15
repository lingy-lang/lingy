use strict; use warnings;
package Lingy::Lang::Atom;

use Lingy::Common;
use base SCALARTYPE;

sub new {
    bless [$_[1] // die], $_[0];
}

1;

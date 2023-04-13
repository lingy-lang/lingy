use strict; use warnings;
package Lingy::Lang::Atom;

use base 'Lingy::Lang::ScalarClass';

sub new {
    bless [$_[1] // die], $_[0];
}

1;

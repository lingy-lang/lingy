package Lingy::Lang::Atom;

use Lingy::Lang::Base 'Scalar';

sub new {
    bless [$_[1] // die], $_[0];
}

1;

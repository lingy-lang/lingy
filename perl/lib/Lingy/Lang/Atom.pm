package Lingy::Lang::Atom;

use Lingy::Base 'Scalar';

use constant lingy_class => 'host.lang.Atom';

sub new {
    bless [$_[1] // die], $_[0];
}

1;

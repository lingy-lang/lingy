use strict; use warnings;
package Lingy::StringBuilder;

use Lingy::Common;
use base 'Lingy::String';

sub append {
    my ($self, $str) = @_;
    STRING->new("$self$str");
}

sub reverse {
    STRING->new(join '', reverse split '', "$_[0]");
}

1;

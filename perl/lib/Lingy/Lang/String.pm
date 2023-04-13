use strict; use warnings;
package Lingy::Lang::String;

use base 'Lingy::Lang::ScalarClass';
use Lingy::Common;

# TODO define lingy.string/join
sub join {
    string(
        CORE::join ${Lingy::Lang::RT::str($_[0])},
            map ${Lingy::Lang::RT::str($_)}, @{$_[1]}
    );
}

sub replaceAll {
    my ($str, $pat, $rep) = @_;
    $str =~ s/\Q$pat\E/$rep/g;
    string($str);
}

sub toUpperCase {
    string(uc $_[0]);
}

1;

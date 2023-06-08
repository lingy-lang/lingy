use strict; use warnings;
package Lingy::String;

use Lingy::Common;
use base 'Lingy::ScalarClass';

use overload cmp => \&comp_pair;

# TODO define lingy.string/join
sub join {
    string(
        CORE::join ${Lingy::RT::str($_[0])},
            map ${Lingy::RT::str($_)}, @{$_[1]}
    );
}

sub replaceAll {
    my ($str, $pat, $rep) = @_;
    $str =~ s/\Q$pat\E/$rep/g;
    string($str);
}

sub substring {
    my ($string, $offset1, $offset2) = @_;
    my $length = length $string;
    $offset2 //= NUMBER->new($length);
    err "Begin index out of range '%d' for string length '%d'",
        $offset1, $length
        if $offset1 < 0 or $offset1 > $length;
    err "End index out of range '%d' for string length '%d'",
        $offset2, $length
        if $offset2 < $offset1 or $offset2 > $length;
    string(substr("$string", $offset1, $offset2 - $offset1))
}

sub toLowerCase {
    string(lc $_[0]);
}

sub toUpperCase {
    string(uc $_[0]);
}

sub _to_seq {
    my ($str) = @_;
    return nil unless length $str;
    list([
        map CHARACTER->read("\\$_"), split //, $$str
    ]);
}

1;

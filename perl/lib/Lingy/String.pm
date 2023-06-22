use strict; use warnings;
package Lingy::String;

use Lingy::Common;
use base 'Lingy::ScalarClass';

use overload cmp => \&comp_pair;

sub append {
    my ($self, $str) = @_;
    STRING->new("$self$str");
}

sub endsWith {
    my ($str, $substr) = map "$_", @_;
    my ($l1, $l2) = map length("$_"), @_;
    BOOLEAN->new(
        $l1 >= $l2 and
        substr($str, $l1 - $l2) eq $substr
    );
}

sub replaceAll {
    my ($str, $pat, $rep) = @_;
    $str =~ s/\Q$pat\E/$rep/g;
    STRING->new($str);
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
    STRING->new(substr("$string", $offset1, $offset2 - $offset1))
}

sub toLowerCase {
    STRING->new(lc $_[0]);
}

sub toString {
    $_[0];
}

sub toUpperCase {
    STRING->new(uc $_[0]);
}

sub _to_seq {
    my ($str) = @_;
    return nil unless length $str;
    list([
        map CHARACTER->read("\\$_"), split //, $$str
    ]);
}

1;

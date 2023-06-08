use strict; use warnings;
package Lingy::Character;

use base 'Lingy::ScalarClass';

use overload cmp => \&comp_pair;

use Lingy::Common;

my %name_to_char = (
    backspace => "\b",
    tab => "\t",
    newline => "\n",
    formfeed => "\f",
    return => "\r",
    space => " ",
);

my %char_to_name = ( reverse %name_to_char );

sub read {
    my ($class, $char) = @_;
    my $type = ref($char);

    if ($type eq '' or
        $type eq SYMBOL
    ) {
        $char =~ s/^\\// or die;
        if (length($char) > 1) {
            $char = $name_to_char{$char} or
                err "Unsupported character: '$_[1]'"
        }
        return $class->new($char);
    }
    if ($type eq NUMBER) {
        return $class->new(chr(0 + $char));
    }
}

sub print {
    my ($char, $raw) = @_;
    return $char if $raw;
    if (my $name = $char_to_name{$char}) {
        return "\\$name";
    }
    return "\\$char";
}

sub _to_str {
    my ($char) = @_;
}

1;

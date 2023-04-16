use strict; use warnings;
package Lingy::Lang::Character;

use base 'Lingy::Lang::ScalarClass';

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
        $type eq 'Lingy::Lang::Symbol'
    ) {
        $char =~ s/^\\// or die;
        if (length($char) > 1) {
            $char = $name_to_char{$char} or
                err "Unsupported character: '$_[1]'"
        }
        return $class->new($char);
    }
    if ($type eq 'Lingy::Lang::Number') {
        return $class->new(chr(0 + $char));
    }
}

sub print {
    my ($char) = @_;
    if (my $name = $char_to_name{$char}) {
        return "\\$name";
    }
    return "\\$char";
}

1;

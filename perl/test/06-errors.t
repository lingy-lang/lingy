use strict; use warnings;

use Test::More;

use lib 'lib';

use Lingy::Runtime;

my $rt = Lingy::Runtime->new;

sub test {
    my ($input, $want, $label) = @_;

    $label //= "'$input' -> '$want'";

    eval { $rt->rep($input) };
    my $got = $@;
    chomp $got;

    if (ref($want) eq 'Regexp') {
        like $got, $want, $label;
    } else {
        is $got, $want, $label;
    }
}

test '(fn ())',
    "fn signature not a vector";
test '(fn ([& a]) ([& b]))',
    "Can't have more than 1 variadic overload";
test '(fn ([x]) ([y]))',
    "Can't have 2 overloads with same arity";
test '(fn ([& x]) ([y z]))',
    "Can't have fixed arity function with more params than variadic function";

done_testing;

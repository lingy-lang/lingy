use strict; use warnings;

use Test::More;

use lib 'lib';

use Lingy::Runtime;

my $rt = Lingy::Runtime->new;

sub test {
    my ($input, $want, $label) = @_;

    $label //= "rep('$input') is ok";

    is join("\n", $rt->rep($input)),
        $want,
        $label;
}

$rt->rep(q<
  (def add1 (fn
    [a b] (+ a b)))
>);

test '(add1 2 2)', "4",
    "Simple 'add' fn";

# $rt->rep(q<
#   (def add2 (fn
#     ([] 0)
#     ([a] a)
#     ([a b] (+ a b))))
# >);

# test '(add2)', "0",
#     "Multi-arity 'add' fn";

done_testing;

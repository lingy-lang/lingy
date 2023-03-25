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

$rt->rep(q<
  (def add2 (fn
    ([] 0)
    ([a] a)
    ([a b] (+ a b))
    ([a b & c] (apply add2 (+ a b) c))))
>);

test '(add2)', "0";
test '(add2 5)', "5";
test '(add2 4 5)', "9";
test '(add2 4 5 6)', "15";
test '(add2 1 2 3 4 5 6 7 8 9)', "45";

done_testing;

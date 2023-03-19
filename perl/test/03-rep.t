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

test '5 (+ 3 3) 7', "5\n6\n7",
    "Multiple expressions on one line works";

done_testing;

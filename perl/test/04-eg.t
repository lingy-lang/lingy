use strict; use warnings;

use Test::More;
use Capture::Tiny;

use lib 'lib';

use Lingy::Runtime;

my $rt = Lingy::Runtime->new;

my $cmd = './bin/lingy eg/99-bottles.ly 3';
my ($out) = Capture::Tiny::capture { system $cmd };
is $out, <<'...', "Program works: '$cmd'";
3 bottles of beer on the wall
3 bottles of beer
Take one down, pass it around
2 bottles of beer on the wall.

2 bottles of beer on the wall
2 bottles of beer
Take one down, pass it around
1 bottles of beer on the wall.

1 bottles of beer on the wall
1 bottles of beer
Take one down, pass it around
0 bottles of beer on the wall.

...

done_testing;

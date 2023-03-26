use Lingy::Test;

my $eg =
    -d 'eg' ? 'eg' :
    -d 'example' ? 'example' :
    die "Can't find eg/example directory";
my $cmd = "$lingy $eg/99-bottles.ly 3";
my ($out) = capture { system $cmd };
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

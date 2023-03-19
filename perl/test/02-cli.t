use strict; use warnings;

use Test::More;

use File::Temp qw( tempfile );

$ENV{LINGY_TEST} = 1;

my $lingy = './bin/lingy';

sub run_is {
    my ($cmd, $want) = @_;
    my $got = `( $cmd ) 2>&1`;
    if (ref($want) eq 'Regexp') {
        like $got, $want, $cmd;
    } else {
        chomp $got;
        is $got, $want, $cmd;
    }
}

note "Testing 'lingy' CLI usages:";

run_is qq<$lingy -e '(prn (+ 2 3))'>, 5;

run_is qq<echo '(prn (+ 9 9))' | $lingy ->, 18;

run_is qq<echo '(prn (+ 9 9))' | $lingy>, 18;

run_is qq<$lingy -p -e '(prn (+ 2 3))'>,
    qr/--- \(prn \(\+ 2 3\)\)/;

run_is qq<$lingy -x -e '(prn (+ 2 3))'>,
    qr/--- !perl\/array:list
- !perl\/scalar:symbol
  =: prn
- !perl\/array:list
  - !perl\/scalar:symbol
    =: \+
  - !perl\/scalar:number
    =: '2'
  - !perl\/scalar:number
    =: '3'/;

my ($fh, $file) = tempfile('lingy-test-file-XXXX', SUFFIX => '.ly');
print $fh "(prn (+ 9 9))\n";
close $fh;
run_is qq<$lingy $file>, 18;
unlink $file;

done_testing;

use Lingy::Test;

use Lingy::Reader;
use Lingy::Printer;

my $reader = Lingy::Reader->new;
my $printer = Lingy::Printer->new;

sub tst {
    my ($str, $want) = @_;
    $want //= $str;
    my ($got) = Lingy::Printer::pr_str($reader->read_str($str));
    if (ref($want) eq 'Regexp') {
        like $got, $want, "'$str' -> '$want'";
    } else {
        is $got, $want, "'$str' -> '$want'";
    }
}

tst '(  foo  )',
    '(foo)';
tst '42';
tst ':42';
tst '"xyz"';
tst '(fn [x])';
tst '(defn f1 [x] (prn x))';
tst '[1,  2,3]',
    '[1 2 3]';
tst '{:foo 1 :bar 2}';
tst "'(foo#)",
    "(quote (foo#))";
tst '`(foo#)',
    qr/^\Q(quasiquote (foo__\E\d+\Q__auto__))\E$/;

tst "(1) (2)", '(1)';
tst "(1) (2)", '(1)';


done_testing;

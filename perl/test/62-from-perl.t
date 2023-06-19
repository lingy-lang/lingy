use Test::More;

use Lingy;

my $lingy = Lingy->new;

is $lingy->rep("(+ 1 2 3 4 5)"), 15,
    "Eval Lingy from Perl works";

is $lingy->rep("(defn add2 [x y] (+ x y))"), 'user/add2',
    "Defined Lingy function";

is $lingy->rep("(add2 5 6)"), 11,
    "Called our defined Lingy function";

eval { $lingy->rep("(add2 5)") };
is $@, "Lingy Error: Wrong number of args (1) passed to function\n",
    "Error, too few args to our Lingy function";

eval { $lingy->rep("(add2 5 6 7)") };
is $@, "Lingy Error: Wrong number of args (3) passed to function\n",
    "Error, too many args to our Lingy function";

my $form = $lingy->read('(+ 1 2 3)');

is ref($form), 'Lingy::List',
    '$lingy->read works';

my $print = $lingy->print($form);

is $print, '(+ 1 2 3)',
    '$lingy->print works';

my $result = $lingy->eval($form);
is ref($result), 'Lingy::Number',
    '$lingy->eval($form) returns a Lingy form';
is $lingy->print($result), 6,
    '$lingy->eval result is correct';

is $result->unbox, 6,
    '$lingy->eval result supports ->unbox';

done_testing;

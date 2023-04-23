use Lingy::Test;

test '5 (+ 3 3) 7', "5\n6\n7",
    "Multiple expressions on one line works";

test '(+)', "0";
test '(+ 2)', "2";
test '(+ 2 3)', "5";
test '(+ 2 3 4)', "9";
test '(+ 2 3 4 5)', "14";
test '(+ 2 3 4 5 6)', "20";

test '(-)', "0";
test '(- 2)', "-2";
test '(- 2 3)', "-1";
test '(- 2 3 4)', "-5";
test '(- 2 3 4 5)', "-10";

test '(*)', "Wrong number of args (0) passed to function";
test '(* 2)', "2";
test '(* 2 3)', "6";
test '(* 2 3 4)', "24";
test '(* 2 3 4 5)', "120";

test '(/)', "Wrong number of args (0) passed to function";
test '(/ 2)', "0.5";
test '(/ 360 2)', "180";
test '(/ 360 2 3)', "60";
test '(/ 360 2 3 4)', "15";
test '(/ 360 2 3 4 5)', "3";

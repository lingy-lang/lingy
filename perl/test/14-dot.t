use Lingy::Test;

# TODO All classes in java.lang are automatically imported to every namespace.

test q<(. "foo" (toUpperCase))>, '"FOO"';
test q<(. "foo" toUpperCase)>, '"FOO"';
test q<(.toUpperCase "foo")>, '"FOO"';
rep '(def var1 "foo")';
test q<(. var1 toUpperCase)>, '"FOO"';

test q<(. (str "foo" "bar") toUpperCase)>, '"FOOBAR"';
test q<(. (str "foo" "bar") (toUpperCase))>, '"FOOBAR"';
test q<(.toUpperCase (str "foo" "bar"))>, '"FOOBAR"';

test q<(. "foo" replaceAll "" "-")>, '"-f-o-o-"';
test q<(. "foo" (replaceAll "" "-"))>, '"-f-o-o-"';
test q<(.replaceAll "foo" "" "-")>, '"-f-o-o-"';
test q<(.replaceAll "foo" "o" "-")>, '"f--"';

test q<(. lingy.lang.Numbers (remainder 8 3))>, '2';
rep "(def x 8) (def y 3)";
test q<(. lingy.lang.Numbers (remainder x y))>, '2';

done_testing;

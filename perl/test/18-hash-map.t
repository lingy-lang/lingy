use Lingy::Test;

test '(def h1 {:foo 123})',
     "user/h1";
test 'h1',
     '{:foo 123}';
test '(:foo h1)',
     '123';
test '(:foo h1)',
     '123';

test '(:bar h1)',
     'nil';
test '(:foo {})',
     'nil';

test '(:bar h1 42)',
     '42';
test '(:foo {} 42)',
     '42';

test '(:foo)',
     "Wrong number of args (0) passed to: ':foo'";
test '(:foo {} 111 222)',
     "Wrong number of args (3) passed to: ':foo'";

test '((keyword "foo") (assoc {} :foo 123) (number 42))',
     '123';

done_testing;

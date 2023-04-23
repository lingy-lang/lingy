use Lingy::Test;

test '#"fo+o"',
     '#"(?^:fo+o)"';

test '(re-pattern "fo+o")',
     '#"(?^:fo+o)"';

test '(re-find #"foo" "foobar")',
     '"foo"';

test '(re-find #"foo" "bar")',
     'nil';

test '(re-find #"(f)(o)(o)" "foobar")',
     '["foo" "f" "o" "o"]';

test '(re-matches #"fo*bar" "foooobar")',
     '"foooobar"';

test '(re-matches #"f(o*)bar" "foooobar")',
     '["foooobar" "oooo"]';

test '(re-matches #"fo*bar" "foooobarbaz")',
     'nil';

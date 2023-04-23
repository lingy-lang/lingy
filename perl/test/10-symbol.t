use Lingy::Test;

test "'foo.bar/baz", 'foo.bar/baz';

rep '(def aaa 123)';

test "aaa", 123;
test "user/aaa", 123;

test "not", "#<Function>";

test "user/abc", "Unable to resolve symbol: 'user/abc' in this context";

test "(def foo/bar 42)", "Can't def a qualified symbol: 'foo/bar'";

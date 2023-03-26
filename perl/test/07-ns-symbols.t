use Lingy::Test;

test "'foo.bar/baz", 'foo.bar/baz';

rep <<'';
(def aaa 123)

test "aaa", 123;

# test '*ns*', 'user';

done_testing;

use Lingy::Test;

test "(foo)", "Unable to resolve symbol: 'foo' in this context";
test "(use 'test.lingy)", 'nil';
test "(foo)", '"called test.lingy/foo"';
test "(test.lingy/foo)", '"called test.lingy/foo"';
test "(user/foo)", '"called test.lingy/foo"';
test "(resolve 'bar)", "#'test.lingy/bar";

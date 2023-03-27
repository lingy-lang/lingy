use Lingy::Test;

test "(foo)", "Unable to resolve symbol: 'foo' in this context";
test "(use 'test.lingy)", 'nil';
test "(foo)", '"called test.lingy/foo"';

done_testing;

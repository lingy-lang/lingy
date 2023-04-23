use Lingy::Test;

test q<{ :zero 0 "foo" 1 'bar 2 42 3 }>,
     q<{:zero 0, "foo" 1, bar 2, 42 3}>;

test q<(seq { :zero 0 "foo" 1 'bar 2 42 3 })>,
     q<([:zero 0] ["foo" 1] [bar 2] [42 3])>;

use Lingy::Test;

test q<(seq { :zero 0 "foo" 1 'bar 2 42 3 })>,
     q<([:zero 0] ["foo" 1] [bar 2] [42 3])>;

test q<(seq "foo")>,
     q<(\f \o \o)>;

test q<(seq '(1 2 3))>,
     q<(1 2 3)>;

test q<(seq '[4 5 6])>,
     q<(4 5 6)>;

test q<(seq {})>, 'nil';
test q<(seq "")>, 'nil';
test q<(seq '())>, 'nil';
test q<(seq '[])>, 'nil';
test q<(seq nil)>, 'nil';

test q<(seq 42)>,
     "Don't know how to create ISeq from: lingy.lang.Number";
test q<(seq 'x)>,
     "Don't know how to create ISeq from: lingy.lang.Symbol";
test q<(seq :x)>,
     "Don't know how to create ISeq from: lingy.lang.Keyword";

use Lingy::Test;

use lib './test/lib';

test "(import Scalar.Util)", 'nil';
test "(import YAML.PP)", 'YAML.PP';

test 'Foo.Class', "Class not found: 'Foo.Class'";
test "(import Foo.Class)", 'Foo.Class';
test 'Foo.Class', 'Foo.Class';
test '(type Foo.Class)', 'lingy.lang.Class';
test "(. Foo.Class foo)", '42';
test "(find-ns 'Foo.Class)", 'nil',
     "Foo.Class is not a namespace";
test '(class? Foo.Class)', 'true';

test '(import Foo.Space)', "Class not found: 'Foo.Space'";

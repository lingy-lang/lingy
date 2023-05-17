use Lingy::Test;

use lib './test/lib';

test "(import Scalar.Util)", 'nil';
test "(import YAML.PP)", 'YAML.PP';

test "(import Foo.Bar)", 'Foo.Bar';
# test "(Foo.Bar/foo)", '42';

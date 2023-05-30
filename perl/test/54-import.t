use Lingy::Test;

use lib './test/lib';

tests <<'...';
- - (import Scalar.Util)
  - nil
- - (import YAML.PP)
  - YAML.PP

- - Foo.Class
  - "Class not found: 'Foo.Class'"
- - (import Foo.Class)
  - Foo.Class
- - Foo.Class
  - Foo.Class
- - (type Foo.Class)
  - lingy.lang.Class
- - (. Foo.Class foo)
  - 42
- - (find-ns 'Foo.Class)
  - nil
  - Foo.Class is not a namespace
- - (class? Foo.Class)
  - 'true'

- - (import Foo.Space)
  - "Class not found: 'Foo.Space'"
...

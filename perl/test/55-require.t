use Lingy::Test;

use lib './test/lib';

tests <<'...';
- [ (require 'test.lang), nil ]
- [ (find-ns 'test.lang), '#<Namespace test.lang>' ]
- [ (test.lang/foo), '"called test.lang/foo"' ]
- [ (ns-name 'test.lang), test.lang ]

- [ (ns-name *ns*), user ]

- [ (require 'test.lingy), nil ]
- [ (test.lingy/foo), '"called test.lingy/foo"' ]

- [ (ns-name *ns*), user ]

- - (foo)
  - "Unable to resolve symbol: 'foo' in this context"
- [ (refer 'test.lingy), nil ]
- [ (foo), '"called test.lingy/foo"' ]

- [ (require 'x.y.z), "Can't find library for (require 'x.y.z)" ]
- [ (refer 'x.y.z), "No namespace: 'x.y.z'" ]

- - (require 'Foo.Class)
  - "Can't require Foo.Class. Foo::Class is not a Lingy::Namespace."

- [ (require 'Foo.Bar), nil ]
- [ (find-ns 'Foo.Bar), '#<Namespace Foo.Bar>' ]
- [ (Foo.Bar/bar), 43 ]
- [ (Foo.Bar/foo), 123 ]
...

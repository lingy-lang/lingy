use Lingy::Test;

use lib './test/lib';

test "(require 'test.lang)", 'nil';
test "(test.lang/foo)", '"called test.lang/foo"';
test "(ns-name 'test.lang)", "test.lang";

test "(ns-name *ns*)", 'user';

test "(require 'test.lingy)", 'nil';
test "(test.lingy/foo)", '"called test.lingy/foo"';

test "(ns-name *ns*)", 'user';

test "(foo)", "Unable to resolve symbol: 'foo' in this context";
test "(refer 'test.lingy)", 'nil';
test "(foo)", '"called test.lingy/foo"';

test "(require 'x.y.z)", "Can't find library for (require 'x.y.z)";
test "(refer 'x.y.z)", "No namespace: 'x.y.z'";

test "(require 'Foo.Class)", "Can't require Foo.Class. Foo::Class is not a Lingy::Namespace.";

test "(require 'Foo.Bar)", 'nil';
test "(Foo.Bar/bar)", '43';
test "(Foo.Bar/foo)", '123';

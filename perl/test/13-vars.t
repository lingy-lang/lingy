use Lingy::Test;

test "(type 42)",
    'host.lang.Number';
test '(type "foo")',
    'host.lang.String';
test "(type 'cymbal)",
    'host.lang.Symbol';
test "(type 'cymbal/monkey)",
    'host.lang.Symbol';
test "(type '(cymbal))",
    'host.lang.List';
test "(type '[cymbal])",
    'host.lang.Vector';
test "(type ['cymbal])",
    'host.lang.Vector';
test "(type `(cymbal))",
    'host.lang.List';
test "(type ())",
    'host.lang.List';
test "(type nil)",
    'host.lang.Nil';
test "(type false)",
    'host.lang.Boolean';
test "(type (fn []))",
    'host.lang.Function';
test "(do (defmacro x [] ()) (type x))",
    'macro';
test "(type (atom 22))",
    'host.lang.Atom';
test "(type {})",
    'host.lang.HashMap';
test "(type :lala)",
    'host.lang.Keyword';
test "(type (type :lala))",
    'host.lang.Type';

test "(name 'foo)",
    '"foo"';
test "(namespace 'foo)",
    'nil';
test "(name 'foo/bar)",
    '"bar"';
test "(namespace 'foo/bar)",
    '"foo"';

test '(gensym)',
    qr/^G__\d+$/;
test '(gensym "foo--")',
    qr/^foo--\d+$/;

test "(resolve 'lingy.core/+)",
    "#'lingy.core/+";
test "(resolve '+)",
    "#'lingy.core/+";
test "(resolve 'user/+)",
    "#'lingy.core/+";
test "(resolve 'luser/+)",
    "nil";
test "(resolve 'user/+++)",
    "nil";
test "(resolve '+++)",
    "nil";
test "(resolve 'add)",
    "nil";
test "(resolve 'lingy.lang.Numbers/add)",
    "#'lingy.lang.Numbers/add";

test "(var v1)",
    "Unable to resolve var: 'v1' in this context";
rep "(def v1 123)";
test "(var v1)",
    "#'v1";

done_testing;

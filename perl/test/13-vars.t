use Lingy::Test;

test "(type 42)",
    'lingy.lang.Number';
test '(type "foo")',
    'lingy.lang.String';
test "(type 'cymbal)",
    'lingy.lang.Symbol';
test "(type 'cymbal/monkey)",
    'lingy.lang.Symbol';
test "(type '(cymbal))",
    'lingy.lang.List';
test "(type '[cymbal])",
    'lingy.lang.Vector';
test "(type ['cymbal])",
    'lingy.lang.Vector';
test "(type `(cymbal))",
    'lingy.lang.List';
test "(type ())",
    'lingy.lang.List';
test "(type nil)",
    'lingy.lang.Nil';
test "(type false)",
    'lingy.lang.Boolean';
test "(type (fn []))",
    'lingy.lang.Function';
test "(do (defmacro x [] ()) (type x))",
    'lingy.lang.Macro';
test "(type (atom 22))",
    'lingy.lang.Atom';
test "(type {})",
    'lingy.lang.HashMap';
test "(type :lala)",
    'lingy.lang.Keyword';
test "(type (type :lala))",
    'lingy.lang.Class';

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
    "nil";

test "(var v1)",
    "Unable to resolve var: 'v1' in this context";
rep "(def v1 123)";
test "(var v1)",
    "#'v1";

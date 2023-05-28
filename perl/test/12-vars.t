use Lingy::Test;

tests <<'...';
- - (type 42)
  - lingy.lang.Number
- - (type "foo")
  - lingy.lang.String
- - (type 'cymbal)
  - lingy.lang.Symbol
- - (type 'cymbal/monkey)
  - lingy.lang.Symbol
- - (type '(cymbal))
  - lingy.lang.List
- - (type '[cymbal])
  - lingy.lang.Vector
- - (type ['cymbal])
  - lingy.lang.Vector
- - (type `(cymbal))
  - lingy.lang.List
- - (type ())
  - lingy.lang.List
- - (type nil)
  - lingy.lang.Nil
- - (type false)
  - lingy.lang.Boolean
- - (type (fn []))
  - lingy.lang.Function
- - (do (defmacro x [] ()) (type x))
  - lingy.lang.Macro
- - (type (atom 22))
  - lingy.lang.Atom
- - (type {})
  - lingy.lang.HashMap
- - (type :lala)
  - lingy.lang.Keyword
- - (type (type :lala))
  - lingy.lang.Class

- - (name 'foo)
  - '"foo"'
- - (namespace 'foo)
  - 'nil'
- - (name 'foo/bar)
  - '"bar"'
- - (namespace 'foo/bar)
  - '"foo"'

- - '(gensym)'
  - /^G__\d+$/
- - '(gensym "foo--")'
  - /^foo--\d+$/

- - (resolve 'lingy.core/+)
  - "#'lingy.core/+"
- - (resolve '+)
  - "#'lingy.core/+"
- - (resolve 'user/+)
  - "#'lingy.core/+"
- - (resolve 'luser/+)
  - nil
- - (resolve 'user/+++)
  - nil
- - (resolve '+++)
  - nil
- - (resolve 'add)
  - nil
- - (resolve 'lingy.lang.Numbers/add)
  - nil

- - (var v1)
  - "Unable to resolve var: 'v1' in this context"
- rep: (def v1 123)
- - (var v1)
  - "#'v1"
...

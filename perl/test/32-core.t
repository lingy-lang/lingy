use Lingy::Test;

tests <<'...'

- note: Testing (list* ...)
- - (list* ())
  - nil
- - (list* 5 ())
  - (5)
- - (list* 5 6 ())
  - (5 6)
- - (list* 5 6 '(2 3))
  - (5 6 2 3)

- note: Testing classes
- - lingy.lang.String
  - lingy.lang.String
- - String
  - lingy.lang.String

- - (type 42)
  - lingy.lang.Number
- - (type (type 42))
  - lingy.lang.Class
- - (type Number)
  - lingy.lang.Class

- - (instance? String "")
  - 'true'
- - (instance? String (str "x" "y"))
  - 'true'
- - (instance? String 123)
  - 'false'

- - (not= 4 (+ 2 2))
  - 'false'
...

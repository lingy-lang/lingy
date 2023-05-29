use Lingy::Test;

tests <<'...';
- - (def h1 {:foo 123})
  - user/h1
- - h1
  - '{:foo 123}'
- - (:foo h1)
  - 123
- - (:foo h1)
  - 123

- - (:bar h1)
  - nil
- - (:foo {})
  - nil

- - (:bar h1 42)
  - 42
- - (:foo {} 42)
  - 42

- - (:foo)
  - "Wrong number of args (0) passed to: ':foo'"
- - (:foo {} 111 222)
  - "Wrong number of args (3) passed to: ':foo'"

- - '{:foo 1 :bar 2 :foo 3}'
  - "Duplicate key: ':foo'"

- - '(assoc {:foo 1 :bar 2} :foo 3)'
  - '{:foo 3, :bar 2}'

- - '(hash-map :foo 1 :bar 2 :foo 3)'
  - '{:bar 2, :foo 3}'

- - ((keyword "foo") (assoc {} :foo 123) (number 42))
  - 123

- - '{ :zero 0 "foo" 1 ''bar 2 42 3 }'
  - '{:zero 0, "foo" 1, bar 2, 42 3}'

- - (seq { :zero 0 "foo" 1 'bar 2 42 3 })
  - ([:zero 0] ["foo" 1] [bar 2] [42 3])
...

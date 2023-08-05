#!/usr/bin/env lingy-test

T=> (def h1 {:foo 123})
 == user/h1

T=> h1
 == {:foo 123}

T=> (:foo h1)
 == 123

T=> (:foo h1)
 == 123

T=> (:bar h1)
 == nil

T=> (:foo {})
 == nil

T=> (:bar h1 42)
 == 42

T=> (:foo {} 42)
 == 42

T=> (:foo)
 == Wrong number of args (0) passed to: ':foo'

T=> (:foo {} 111 222)
 == Wrong number of args (3) passed to: ':foo'

T=> {:foo 1 :bar 2 :foo 3}
 == Duplicate key: ':foo'

T=> (assoc {:foo 1 :bar 2} :foo 3)
 == {:foo 3, :bar 2}

T=> (hash-map :foo 1 :bar 2 :foo 3)
 == {:bar 2, :foo 3}

T=> ((keyword "foo") (assoc {} :foo 123) (number 42))
 == 123

T=> { :zero 0 "foo" 1 'bar 2 42 3 }
 == {:zero 0, "foo" 1, bar 2, 42 3}

T=> (seq { :zero 0 "foo" 1 'bar 2 42 3 })
 == ([:zero 0] ["foo" 1] [bar 2] [42 3])

# vim: ft=txt:

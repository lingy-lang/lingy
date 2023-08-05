#!/usr/bin/env lingy-test

T=> (def v1 [:foo 123])
 == user/v1

T=> v1
 == [:foo 123]

T=> (v1 0)
 == :foo

T=> (v1 1)
 == 123

T=> (v1)
 == Wrong number of args (0) passed to: 'lingy.lang.Vector'

T=> (v1 0 1)
 == Wrong number of args (2) passed to: 'lingy.lang.Vector'

T=> ((vector 3 6 9) (- 5 4))
 == 6

T=> (let [x ([42] 0)] x)
 == 42

T=> (defn f1 [v] (let [x (v 0)] x))
 == user/f1

T=> (f1 [3 4])
 == 3

# vim: ft=txt:

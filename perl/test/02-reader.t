#!/usr/bin/env lingy-test

P=> (  foo  )
 == (foo)

P=> 42
 == 42

P=> :42
 == :42

P=> "xyz"
 == "xyz"

P=> (fn [x])
 == (fn [x])

P=> (defn f1 [x] (prn x))
 == (defn f1 [x] (prn x))

P=> [1,  2,3]
 == [1 2 3]

P=> {:foo 1, :bar 2}
 == {:foo 1, :bar 2}

P=> '(foo#)
 == (quote (foo#))

P=> `(foo#)
 =~ ^\Q(quasiquote (foo__\E\d+\Q__auto__))\E$

P=> (1) (2)
 == (1)

P=> (1) (2)
 == (1)

T=> ())
 == Unmatched delimiter: ')'

T=> foo]
 == Unmatched delimiter: ']'

T=> ,}
 == Unmatched delimiter: '}'

; Shebang syntax is a comment
T=> 111 222 #!/bin/bash 333
 == 111
 == 222

# vim: ft=txt:

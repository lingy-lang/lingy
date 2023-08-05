#!/usr/bin/env lingy-test

T=> (foo)
 == Unable to resolve symbol: 'foo' in this context

T=> (use 'test.lingy)
 == nil

T=> (foo)
 == "called test.lingy/foo"

; XXX Regression
# T=> (test.lingy/foo)
#  == "called test.lingy/foo"

T=> (user/foo)
 == "called test.lingy/foo"

; XXX Regression
# T=> (resolve 'bar)
#  == #'test.lingy/bar

T=> (use 'lingy.devel)
 == nil

# vim: ft=txt:

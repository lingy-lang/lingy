#!/usr/bin/env lingy-test

; def a var
T=> (def aaa 123)
 == user/aaa

; Quoted FQ symbol
T=> 'foo.bar/baz
 == foo.bar/baz

; Eval a symbol
T=> aaa
 == 123

; Eval a FQ symbol
T=> user/aaa
 == 123

T=> not
 == #<Function>

T=> user/abc
 == Unable to resolve symbol: 'user/abc' in this context

T=> (def foo/bar 42)
 == Can't def a qualified symbol: 'foo/bar'

# vim: ft=txt:

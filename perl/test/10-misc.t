#!/usr/bin/env lingy-test

T=> (declare x)
 == user/x

T=> (declare a b c)
 == user/c

T=> (ns-map *ns*)
 =~ HashMap lingy.lang.HashMap

# vim: ft=txt:

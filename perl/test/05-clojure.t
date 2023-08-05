#!/usr/bin/env lingy-test

T=> (time (clojure-require 'clojure.core))
 == nil
O=~ Elapsed time: \d+\.\d+ msecs

# vim: ft=txt:

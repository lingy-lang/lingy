#!/usr/bin/env lingy

(ns testing
  (:use
    lingy.devel
    lingy.testing.tap))

(note "Testing with lingy.test")

(is (str "f" "oo") "foo" "(is ...) ; works")
(ok "foo" "(ok ...) ; works")
(pass "(pass ...) ; works")

(done-testing)

; vim: ft=clojure:

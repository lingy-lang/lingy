(ns Foo.Bar)
(import Foo.BarClass)

(defn bar [] (. Foo.BarClass foo))

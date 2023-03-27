; Create standard calls from special forms:
(defmacro! defmacro
  (fn* [name & body]
    `(defmacro! ~name (fn* ~@body))))

(defmacro def [& xs] (cons 'def! xs))

(defmacro fn [& xs] (cons 'fn* xs))

(defmacro defn [name & body]
  `(def ~name (fn ~@body)))

(defmacro let [& xs] (cons 'let* xs))
(defmacro try [& xs] (cons 'try* xs))


; Basic math ops:
(defn +
  ([] 0)
  ([x] x)
  ([x y] (lingy.lang.Numbers/add x y))
  ([x y & more]
    (reduce + (+ x y) more)))

(defn -
  ([] 0)
  ([x] (lingy.lang.Numbers/minus 0 x))
  ([x y] (lingy.lang.Numbers/minus x y))
  ([x y & more]
    (reduce - (- x y) more)))

(defn *
  ([x] x)
  ([x y] (lingy.lang.Numbers/multiply x y))
  ([x y & more]
    (reduce * (* x y) more)))

(defn /
  ([x] (lingy.lang.Numbers/divide 1 x))
  ([x y] (lingy.lang.Numbers/divide x y))
  ([x y & more]
    (reduce / (/ x y) more)))

(defn == ([& xs] (apply = xs)))

(defn =
  ([x] true)
  ([x y] (lingy.lang.Numbers/equiv x y))
  ([x y & more]
    (if (= x y)
      (if (next more)
        (recur y (first more) (next more))
        (= y (first more)))
      false)))

(defn <
  ([x] true)
  ([x y] (lingy.lang.Numbers/lt x y))
  ([x y & more]
    (if (< x y)
      (if (next more)
        (recur y (first more) (next more))
        (< y (first more)))
      false)))

(defn <=
  ([x] true)
  ([x y] (lingy.lang.Numbers/lte x y))
  ([x y & more]
    (if (<= x y)
      (if (next more)
        (recur y (first more) (next more))
        (<= y (first more)))
      false)))

(defn >
  ([x] true)
  ([x y] (lingy.lang.Numbers/gt x y))
  ([x y & more]
    (if (> x y)
      (if (next more)
        (recur y (first more) (next more))
        (> y (first more)))
      false)))

(defn >=
  ([x] true)
  ([x y] (lingy.lang.Numbers/gte x y))
  ([x y & more]
    (if (>= x y)
      (if (next more)
        (recur y (first more) (next more))
        (>= y (first more)))
      false)))

; Other macros and functions:
(defmacro ->
  [x & forms]
  (loop [x x, forms forms]
    (if forms
      (let [
        form (first forms)
        threaded (
          if (seq? form)
            `(~(first form) ~x ~@(next form))
            (list form x))]
        (recur threaded (next forms)))
      x)))

(defmacro ->>
  [x & forms]
  (loop [x x, forms forms]
    (if forms
      (let [
        form (first forms)
        threaded (
          if (seq? form)
            `(~(first form) ~@(next form) ~x)
            (list form x))]
        (recur threaded (next forms)))
      x)))

(defmacro comment [& body] nil)

(defmacro cond [& xs]
  (if (> (count xs) 0)
    (list 'if (first xs)
      (if (> (count xs) 1)
        (nth xs 1)
        (throw "odd number of forms to cond"))
      (cons 'cond (rest (rest xs))))))

(defn gensym
  ([] (gensym "G__"))
  ([prefix-string]
    (. lingy.lang.Symbol
      (intern
        (str
          prefix-string
          (str (. lingy.lang.RT (nextID))))))))

(defn load-file [f]
  (eval
    (read-string
      (str
        "(do "
        (slurp f)
        "\nnil)"))))

(defn mod
  [num div]
  (let [m (rem num div)]
    (if (or (zero? m) (= (pos? num) (pos? div)))
      m
      (+ m div))))

(defn not [a]
  (if a
    false
    true))

(defmacro ns [name] `(-ns '~name))

(defmacro or
  ([] nil)
  ([x] x)
  ([x & next]
      `(let [or0000 ~x]
         (if or0000 or0000 (or ~@next)))))

(defn refer [& xs]
  (apply lingy.lang.RT/refer xs)
  nil)

(defn rem
  [num div]
    (. lingy.lang.Numbers (remainder num div)))

(defn require [& xs]
  (apply lingy.lang.RT/require xs)
  nil)

(defn use [ns]
  (require ns)
  (refer ns))

(defmacro when
  [test & body]
  (list 'if test (cons 'do body)))

(defmacro when-not
  [test & body]
  (list 'if test nil (cons 'do body)))

(defn zero?
  [num] (. lingy.lang.Numbers (isZero num)))

; vim: ft=clojure:

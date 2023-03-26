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
  ([x y] (-add x y))
  ([x y & more]
    (reduce + (+ x y) more)))

(defn -
  ([] 0)
  ([x] (-subtract 0 x))
  ([x y] (-subtract x y))
  ([x y & more]
    (reduce - (- x y) more)))

(defn *
  ([x] x)
  ([x y] (-multiply x y))
  ([x y & more]
    (reduce * (* x y) more)))

(defn /
  ([x] (-divide 1 x))
  ([x y] (-divide x y))
  ([x y & more]
    (reduce / (/ x y) more)))


; Other macros and functions:
(defmacro cond [& xs]
  (if (> (count xs) 0)
    (list 'if (first xs)
      (if (> (count xs) 1)
        (nth xs 1)
        (throw "odd number of forms to cond"))
      (cons 'cond (rest (rest xs))))))

(defn load-file [f]
  (eval
    (read-string
      (str
        "(do "
        (slurp f)
        "\nnil)"))))

(defn not [a]
  (if a
    false
    true))

(defmacro ns [name] `(-ns '~name))

; vim: ft=clojure:

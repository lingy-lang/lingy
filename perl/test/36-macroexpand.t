use Lingy::Test;

tests <<'...';
- - (macroexpand '(defn a ([a b] (+ a b))))
  - (def a (fn* ([a b] (+ a b))))

- - (macroexpand '(fn ([a b] (+ a b))))
  - (fn* ([a b] (+ a b)))

- - (macroexpand '(cond 1 2 3 4 5 6))
  - (if 1 2 (cond 3 4 5 6))

- - (macroexpand '(-> 123 prn))
  - (prn 123)

- - (macroexpand '(-> 42 (/ 6) (* 3) prn))
  - (prn (* (/ 42 6) 3))

- - (macroexpand '(->> 42 (/ 6) (* 3) prn))
  - (prn (* 3 (/ 6 42)))
...

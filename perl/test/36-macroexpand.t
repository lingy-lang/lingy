use Lingy::Test;

test "(macroexpand '(defn a ([a b] (+ a b))))",
    '(def! a (fn ([a b] (+ a b))))';

test "(macroexpand '(fn ([a b] (+ a b))))",
    '(fn* ([a b] (+ a b)))';

test "(macroexpand '(cond 1 2 3 4 5 6))",
    "(if 1 2 (cond 3 4 5 6))";

test "(macroexpand '(-> 123 prn))",
    '(prn 123)';

test "(macroexpand '(-> 42 (/ 6) (* 3) prn))",
    '(prn (* (/ 42 6) 3))';

test "(macroexpand '(->> 42 (/ 6) (* 3) prn))",
    '(prn (* 3 (/ 6 42)))';

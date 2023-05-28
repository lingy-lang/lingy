use Lingy::Test;

tests <<'...';
- rep: |
    (def add1 (fn
      [a b] (+ a b)))

- [ '(add1 2 2)', 4, "Simple 'add' fn" ]

- rep: |
    (def add2 (fn
      ([] 0)
      ([a] a)
      ([a b] (+ a b))
      ([a b & c] (apply add2 (+ a b) c))))

- [ '(add2)', 0 ]
- [ '(add2 5)', 5 ]
- [ '(add2 4 5)', 9 ]
- [ '(add2 4 5 6)', 15 ]
- [ '(add2 1 2 3 4 5 6 7 8 9)', 45 ]
...

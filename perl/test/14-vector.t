use Lingy::Test;

tests <<'...';
- - (def v1 [:foo 123])
  - user/v1
- - v1
  - '[:foo 123]'
- - (v1 0)
  - :foo
- - (v1 1)
  - 123

- - (v1)
  - "Wrong number of args (0) passed to: 'lingy.lang.Vector'"
- - (v1 0 1)
  - "Wrong number of args (2) passed to: 'lingy.lang.Vector'"

- - ((vector 3 6 9) (- 5 4))
  - 6

- - (let [x ([42] 0)] x)
  - 42

- rep: (defn f1 [v] (let [x (v 0)] x))
- - (f1 [3 4])
  - 3
...

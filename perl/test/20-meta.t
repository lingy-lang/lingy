use Lingy::Test;

tests <<'...';
- - (def v1 ^{:m 1 :n 2} [:foo 123])
  - user/v1
- - v1
  - '[:foo 123]'
- - (meta v1)
  - '{:m 1, :n 2}'

- - (def a [1 2])
  - user/a
- - (def b (with-meta a {:foo 123}))
  - user/b
- - (= a b)
  - 'true'
- - (meta a)
  - nil
- - (meta b)
  - '{:foo 123}'

- - (def x ^{:a 11 :b 22} [(+ 2 2)])
  - user/x
- - x
  - '[4]'
- - (meta x)
  - '{:a 11, :b 22}'

- rep: '(def f1 ^{:c 3} #()) (meta f1)'
- - (meta f1)
  - '{:c 3}'

- rep: '(def f2 #())'
- - (meta f2)
  - nil

- rep: (def f3 ^{:d 4} f2) (meta f3)
- - (meta f3)
  - '{:d 4}'
- - (meta f2)
  - nil
...

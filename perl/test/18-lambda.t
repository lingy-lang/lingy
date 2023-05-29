use Lingy::Test;

tests <<'...';
- - (#(%2 %1 %3))
  - Wrong number of args (0) passed to function

- - (#(%2 %1 %3) 6 * 7)
  - 42

- - (read-string "#(%2 %1 %1)")
  - (fn* [p1_12 p2_11] (p2_11 p1_12 p1_12))

- - (read-string "#(+ %5 %2)")
  - (fn* [p1_13 p2_12 p3_14 p4_15 p5_11] (+ p5_11 p2_12))
...

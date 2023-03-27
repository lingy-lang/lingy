use Lingy::Test;

test_out "
  (loop [i 1024]
    (when (pos? i)
      (prn i)
      (recur (quot i 2))))", <<'';
1024
512
256
128
64
32
16
8
4
2
1

test_out "
  (loop [i 3, j 42]
    (when (pos? i)
      (println i j)
      (recur (dec i) 5)))", <<'';
3 42
2 5
1 5

test_out "
  (loop [i 3]
    (when (pos? i)
      (prn i)
      (recur (dec i))))", <<'';
3
2
1

test_out "
  (loop [i 3]
    (when (pos? i)
      (let [j (dec i)]
        (prn i)
        (recur j))))", <<'';
3
2
1

test "
  (loop [i 3 l ()]
    (if (pos? i)
      (recur (dec i) (cons i l))
      l))",
  "(1 2 3)";

done_testing;

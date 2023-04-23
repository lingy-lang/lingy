(ns lingy.testing.tap)

(def counter 0)

(defn pass [label]
  (def counter (inc counter))
  (println (str "ok " counter " - " label)))

(defn fail [label]
  (def counter (inc counter))
  (println (str "not ok " counter " - " label)))

(defn is [got want label]
  (if (= got want)
    (pass label)
    (fail label)))

(defn ok [got label]
  (if got
    (pass label)
    (fail label)))

(defn note [string] (println (str "# " string)))

(defn done-testing [] (println (str "1.." counter)))

; vim: ft=clojure:

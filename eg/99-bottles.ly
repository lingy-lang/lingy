(defn main [number]
  (let [
    paragraphs (map paragraph (range number 0 -1)) ]
    (map println paragraphs)))

(defn paragraph [num]
  (str
    (bottles num) " of beer on the wall,\n"
    (bottles num) " of beer.\n"
    "Take one down, pass it around.\n"
    (bottles (dec num)) " of beer on the wall.\n"))

(defn bottles [n]
  (cond
    (= n 0) "No more bottles"
    (= n 1) "1 bottle"
    :else (str n " bottles")))

(main (nth *command-line-args* 0 99))

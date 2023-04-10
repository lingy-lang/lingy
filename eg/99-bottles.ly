(defn main [n]
  (let [
    paragraphs (map paragraph (range n 0 -1)) ]
    (println
      (lingy.lang.String/join "\n" paragraphs))))

(defn paragraph [num]
  (str
    num " bottles of beer on the wall\n"
    num " bottles of beer\n"
    "Take one down, pass it around\n"
    (dec num) " bottles of beer on the wall.\n"))

(main (nth *ARGV* 0 99))

(defn main []
  (let [
    n
      (if (empty? *ARGV*)
        99
        (number (first *ARGV*))) ]
    (println (lyrics n))))

(defn paragraph [num]
  (str num " bottles of beer on the wall\n"
       num " bottles of beer\n"
       "Take one down, pass it around\n"
       (dec num) " bottles of beer on the wall.\n"))

(defn lyrics [n]
  (let [
    numbers (range n 0)
    paragraphs (map paragraph numbers) ]
    (join "\n" paragraphs)))

(main)

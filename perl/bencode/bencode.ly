(import LingyBencode)

(def data {:age 25 :eyes "blue"})

(def bencoded (LingyBencode/bencode data))

(println bencoded)

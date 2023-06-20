
use Lingy::Test;

tests <<'...';
- - '#_(foo bar 5)'
  - ''
- - '(list 1 2 #_(foo bar 5) 3)'
  - '(1 2 3)'
- - '(list 1 #_ #_ #_ 2 3 4 5 6 #_ 7 8 9)'
  - '(1 5 6 8 9)'
- - '(+ 2 #_[x y z] 3 #_#_ {:a 1 :a 2} {5} 2)'
  - 7
- - '(list 1 #_"x\qb" 2)'
  - (1 2)
- - '#_"a\qb" "a\qb"'
  - Unsupported escape character '\q'
- - '#_#_"a\qb" {:a 1 :a 2} {:b}'
  - Map literal must contain an even number of forms
- - '#_#{a a} #{b b}'
  - "Duplicate key: 'b'"
- - '#_[1 2 3]]'
  - "Unmatched delimiter: ']'"
- - (comment (throw 123))
  - nil
...

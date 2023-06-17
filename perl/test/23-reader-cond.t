use Lingy::Test;

tests <<'...';
- - '#?[:clj "clojure" :lingy.pl "perl"]'
  - read-cond body must be a list

- - '#?(:clj "clojure" :lingy.pl "perl" xxxxx)'
  - read-cond requires an even number of forms

- - '#?(foo "bar" :clj "clojure" :lingy.pl "perl")'
  - 'Feature should be a keyword: foo'

- - '#?(:clj "clojure" :lingy.pl "perl")'
  - '"perl"'

- - '#?(:clj "clojure" :pl "perl")'
  - ''

- - '#?(:default "clojure" :lingy.pl "perl")'
  - '"clojure"'

- - |
    #?(:default
    (+ 1 2)
    )
  - 3
...

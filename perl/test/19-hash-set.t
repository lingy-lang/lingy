use Lingy::Test;

tests <<'...';
- - '(def s1 #{:foo :bar})'
  - user/s1
- - s1
  - '#{:foo :bar}'
- - (:foo s1)
  - :foo

- - (:baz s1)
  - nil
- - '(:foo #{})'
  - nil

- - (:baz s1 42)
  - 42
- - '(:foo #{} 42)'
  - 42

- - '(:foo #{} 111 222)'
  - "Wrong number of args (3) passed to: ':foo'"

- - '#{:foo :bar :foo}'
  - "Duplicate key: ':foo'"

- - '(hash-set :foo :bar :foo)'
  - '#{:bar :foo}'

- - '#{ :zero "foo" ''bar 42}'
  - '#{:zero "foo" bar 42}'

- - '(seq #{ :zero "foo" 42 ''bar })'
  - (:zero "foo" 42 bar)
...

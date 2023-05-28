use Lingy::Test;

tests <<'...';
- - '#"fo+o"'
  - '#"fo+o"'

- - (re-pattern "fo+o")
  - '#"fo+o"'

- - '(re-find #"foo" "foobar")'
  - '"foo"'

- - '(re-find #"foo" "bar")'
  - nil

- - '(re-find #"(f)(o)(o)" "foobar")'
  - '["foo" "f" "o" "o"]'

- - '(re-matches #"fo*bar" "foooobar")'
  - '"foooobar"'

- - '(re-matches #"f(o*)bar" "foooobar")'
  - '["foooobar" "oooo"]'

- - '(re-matches #"fo*bar" "foooobarbaz")'
  - nil
...

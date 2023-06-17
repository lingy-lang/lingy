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

- - '#"\bfoo\b"'
  - '#"\bfoo\b"'

- - >-
    #"\[\]\{\}\(\)\+\*\?\^\$\|"
  - >-
    #"\[\]\{\}\(\)\+\*\?\^\$\|"

- - '(re-matches #"\{{3}(\d+)\+(\}*)" "{{{123+}}}")'
  - '["{{{123+}}}" "123" "}}}"]'

# - - >
#     #"\a\b\c\d\e\f\h\n\r\s\t\u0000\v\w\x00\z\`\~\!\@\#\$\%\^\&\*\(\)\-\_\=\+\{\}\[\]\|\\\:\;\"\'\<\>\,\.\?\/\000\1\2\3\4\5\6\7\8\9\A\B\G\H\Q\R\S\T\U\V\W\X\Y\Z
...

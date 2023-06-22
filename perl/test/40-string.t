use Lingy::Test;

tests <<'...'
- rep: "(use 'lingy.string)"

- - (ends-with? "foo" "o")
  - 'true'
- - (ends-with? "foo" "foo")
  - 'true'
- - (ends-with? "foo" "f")
  - 'false'

- - (join ["f" "oo"])
  - '"foo"'
- - (join "-" ["f" "oo"])
  - '"f-oo"'

- - (reverse "42")
  - '"24"'
...

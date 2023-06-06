use Lingy::Test;

tests <<'...';
- - (foo)
  - "Unable to resolve symbol: 'foo' in this context"

- - (use 'test.lingy)
  - nil

- - (foo)
  - '"called test.lingy/foo"'

- note: XXX Regression
# - - (test.lingy/foo)
#   - '"called test.lingy/foo"'

- - (user/foo)
  - '"called test.lingy/foo"'

- note: XXX Regression
# - - (resolve 'bar)
#   - "#'test.lingy/bar"

- - (use 'lingy.devel)
  - nil
...

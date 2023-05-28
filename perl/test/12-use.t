use Lingy::Test;

tests <<'...';
- - (foo)
  - "Unable to resolve symbol: 'foo' in this context"

- - (use 'test.lingy)
  - nil

- - (foo)
  - '"called test.lingy/foo"'

- - (test.lingy/foo)
  - '"called test.lingy/foo"'

- - (user/foo)
  - '"called test.lingy/foo"'

- - (resolve 'bar)
  - "#'test.lingy/bar"
...

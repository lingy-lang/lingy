use Lingy::Test;

rep '(def aaa 123)';

tests <<'...';
- - "'foo.bar/baz"
  - foo.bar/baz

- - aaa
  - 123
- - user/aaa
  - 123

- - not
  - '#<Function>'

- - user/abc
  - "Unable to resolve symbol: 'user/abc' in this context"

- - (def foo/bar 42)
  - "Can't def a qualified symbol: 'foo/bar'"
...


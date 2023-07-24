use Lingy::Test;

tests <<'...';
- - (
  - ([:zero 0] ["foo" 1] [bar 2] [42 3])

- - (seq "foo")
  - (\f \o \o)

- - (seq '(1 2 3))
  - (1 2 3)

- - (seq '[4 5 6])
  - (4 5 6)

- - (seq {})
  - nil
- - (seq "")
  - nil
- - (seq '())
  - nil
- - (seq '[])
  - nil
- - (seq nil)
  - nil

- - (seq 42)
  - "Don't know how to create ISeq from: lingy.lang.Number"
- - (seq 'x)
  - "Don't know how to create ISeq from: lingy.lang.Symbol"
- - (seq :x)
  - "Don't know how to create ISeq from: lingy.lang.Keyword"
...

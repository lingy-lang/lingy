use Lingy::Test;

# TODO All classes in java.lang are automatically imported to every namespace.

tests <<'...';
- [ (. "foo" (toUpperCase)), '"FOO"' ]
- [ (. "foo" toUpperCase), '"FOO"' ]
- [ (.toUpperCase "foo"), '"FOO"' ]

- rep: (def var1 "foo")
- [ (. var1 toUpperCase), '"FOO"' ]

- [ (. (str "foo" "bar") toUpperCase), '"FOOBAR"' ]
- [ (. (str "foo" "bar") (toUpperCase)), '"FOOBAR"' ]
- [ (.toUpperCase (str "foo" "bar")), '"FOOBAR"' ]

- [ (. "foo" replaceAll "" "-"), '"-f-o-o-"' ]
- [ (. "foo" (replaceAll "" "-")), '"-f-o-o-"' ]
- [ (.replaceAll "foo" "" "-"), '"-f-o-o-"' ]
- [ (.replaceAll "foo" "o" "-"), '"f--"' ]

- [ (. lingy.lang.Numbers (remainder 8 3)), 2 ]

- rep: (def x 8) (def y 3)
- [ (. lingy.lang.Numbers (remainder x y)), 2 ]
...

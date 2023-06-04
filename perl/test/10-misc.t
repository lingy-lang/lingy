use Lingy::Test;

tests <<'...';
- - (declare x)
  - user/x

- - (declare a b c)
  - user/c

- - (ns-map *ns*)
  - /HashMap lingy.lang.HashMap/
...

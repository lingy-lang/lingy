use Lingy::Test;

use lib './test/lib';

tests <<'...';
- [ (use 'lingy.devel), nil ]
- [ (resolve 'WWW), "#'lingy.devel/WWW" ]

- - (WWW (x-class-names))
  - /- Lingy::Lang::Atom/
- - (WWW (x-core-ns))
  - >-
      /cons: !perl/code '\{ "DUMMY" }'/
...

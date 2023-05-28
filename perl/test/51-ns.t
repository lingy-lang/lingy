use Lingy::Test;

tests <<'...';
- [ '*ns*', '#<Namespace user>' ]
- [ (the-ns *ns*), '#<Namespace user>' ]
- [ (the-ns 'user), '#<Namespace user>' ]
- [ (find-ns 'user), '#<Namespace user>' ]
- [ (ns-name *ns*), user ]
- [ (type *ns*), lingy.lang.Namespace ]

- rep: |
    (ns foo)
    (def x 42)
    (ns user)

- [ foo/x, 42 ]
- [ "(find-ns 'foo)", '#<Namespace foo>' ]

- [ (ns foo.bar) (def baz (+ 40 2)), "nil\nfoo.bar/baz" ]
- [ '*ns*', '#<Namespace foo.bar>' ]

- rep: (ns ns1)
- [ inc, '#<Function>' ]
# XXX should be:
# - [ inc, '#<function inc>' ]

- rep: (in-ns 'ns2)
- [ lingy.core/*ns*, "#<Namespace ns2>" ]
- [ (lingy.core/find-ns 'ns2), '#<Namespace ns2>' ]
- [ (lingy.core/the-ns 'ns2), '#<Namespace ns2>' ]
- - inc
  - "Unable to resolve symbol: 'inc' in this context"

- rep: (lingy.core/in-ns 'user)
- [ '*ns*', '#<Namespace user>' ]

- [ (create-ns 'ns3), '#<Namespace ns3>' ]
- [ (find-ns 'ns3), '#<Namespace ns3>' ]
- [ (the-ns 'ns3), '#<Namespace ns3>' ]
- [ (ns-name 'ns3), 'ns3' ]

- [ (the-ns *ns*), '#<Namespace user>' ]
- - (find-ns *ns*)
  - Arg 0 for 'Lingy::Lang::RT::find_ns' must be 'Lingy::Lang::Symbol', not 'Lingy::Namespace'
- [ (ns-name *ns*), user ]

- [ (the-ns 'lingy.core), '#<Namespace lingy.core>' ]
- [ (ns-name (the-ns 'lingy.core)), lingy.core ]

- [ (the-ns 'nope), "No namespace: 'nope' found" ]
- [ (find-ns 'nope), nil ]
...

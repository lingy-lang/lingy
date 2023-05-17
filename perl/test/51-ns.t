use Lingy::Test;

test '*ns*', '#<Namespace user>';

test '(ns-name *ns*)', 'user';

rep <<'';
  (ns foo)
  (def x 42)
  (ns user)

test 'foo/x', '42';

test "(find-ns 'foo)", '#<Namespace foo>';

test "(ns foo.bar) (def baz (+ 40 2))", "nil\nfoo.bar/baz";

test '*ns*', '#<Namespace foo.bar>';

rep '(ns ns1)';

# test 'inc', '#<function inc>';
# XXX fix
test 'inc', '#<Function>';

rep "(in-ns 'ns2)";

test "lingy.core/*ns*", "#<Namespace ns2>";

test 'inc', "Unable to resolve symbol: 'inc' in this context";

rep "(lingy.core/in-ns 'user)";

test "(create-ns 'ns3)", '#<Namespace ns3>';

test '(ns-name *ns*)', 'user';

test "(ns-name (the-ns 'lingy.core))", 'lingy.core';

test "(the-ns 'nope)", "No namespace: 'nope' found";

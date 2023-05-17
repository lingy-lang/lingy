use Lingy::Test;

test '*ns*', '#<Namespace user>';
test '(the-ns *ns*)', '#<Namespace user>';
test "(the-ns 'user)", '#<Namespace user>';
test "(find-ns 'user)", '#<Namespace user>';
test '(ns-name *ns*)', 'user';
test '(type *ns*)', 'lingy.lang.Namespace';

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
test "(lingy.core/find-ns 'ns2)", '#<Namespace ns2>';
test "(lingy.core/the-ns 'ns2)", '#<Namespace ns2>';
test 'inc', "Unable to resolve symbol: 'inc' in this context";

rep "(lingy.core/in-ns 'user)";
test '*ns*', '#<Namespace user>';

test "(create-ns 'ns3)", '#<Namespace ns3>';
test "(find-ns 'ns3)", '#<Namespace ns3>';
test "(the-ns 'ns3)", '#<Namespace ns3>';
test "(ns-name 'ns3)", 'ns3';

test '(the-ns *ns*)', '#<Namespace user>';
test '(find-ns *ns*)', "Arg 0 for 'Lingy::Lang::RT::find_ns' must be 'Lingy::Lang::Symbol', not 'Lingy::Namespace'";
test '(ns-name *ns*)', 'user';

test "(the-ns 'lingy.core)", '#<Namespace lingy.core>';
test "(ns-name (the-ns 'lingy.core))", 'lingy.core';

test "(the-ns 'nope)", "No namespace: 'nope' found";
test "(find-ns 'nope)", "nil";

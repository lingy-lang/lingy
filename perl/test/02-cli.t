use Lingy::Test;

note "Testing 'lingy' CLI usages:";

run_is qq<$lingy -e '(prn (+ 2 3))'>, 5;

run_is qq<echo '(prn (+ 9 9))' | $lingy ->, 18;

run_is qq<echo '(prn (+ 9 9))' | $lingy>, 18;

run_is qq<$lingy -p -e '(prn (+ 2 3))'>,
    qr/--- \(prn \(\+ 2 3\)\)/;

run_is qq<$lingy -x -e '(prn (+ 2 3))'>,
    qr/--- !perl\/array:Lingy::Lang::List
- !perl\/scalar:Lingy::Lang::Symbol
  =: prn
- !perl\/array:Lingy::Lang::List
  - !perl\/scalar:Lingy::Lang::Symbol
    =: \+
  - !perl\/scalar:Lingy::Lang::Number
    =: '2'
  - !perl\/scalar:Lingy::Lang::Number
    =: '3'/,
    "'\$cmd' produces correct YAML dump";

run_is "$lingy test/program1.ly",
    'program: test/program1.ly args: ()';

run_is "$lingy test/program1.ly foo bar",
    'program: test/program1.ly args: (foo bar)';

sub note_repl_input {
    note "Lingy REPL input: '$ENV{LINGY_TEST_INPUT}'";
}

{
    local $ENV{LINGY_TEST_INPUT} = '(prn *file* *ARGV*)';
    note_repl_input;

    run_is "$lingy", qq<"NO_SOURCE_PATH" ()\nnil>;
    run_is "$lingy -r", qq<"NO_SOURCE_PATH" ()\nnil>;

    run_is "$lingy -r foo bar", qq<"NO_SOURCE_PATH" ("foo" "bar")\nnil>;

    local $ENV{LINGY_TEST_INPUT} = '(prn *file* *ARGV* foo)';
    note_repl_input;

    run_is "$lingy -e '(def foo 42)' -r", qq<"NO_SOURCE_PATH" () 42\nnil>;

    run_is "$lingy -e '(def foo 42)'", 'user/foo';
}

done_testing;

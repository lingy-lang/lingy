use Lingy::Test;

note "Testing 'lingy' CLI usages:";

run_is qq<$lingy --help>,
    qr/\QUsage: lingy [<opts>] [<lingy-file-name>]\E/;

run_is qq<$lingy --foo>,
    qr/\QError: Error in command line arguments\E/;

run_is qq<$lingy --version>,
    "Lingy [perl] version $Lingy::VERSION";

run_is qq<$lingy -e '(prn (+ 2 3))'>, 5;

run_is qq<echo '(prn (+ 9 9))' | $lingy ->, 18;

run_is qq<echo '(prn (+ 9 9))' | $lingy>, 18;

run_is qq<$lingy --ppp -e '(prn (+ 2 3))'>,
    qr/--- \(prn \(\+ 2 3\)\)/;

run_is qq<$lingy --xxx -e '(prn (+ 2 3))'>,
    qr/--- !perl\/array:Lingy::List
- !perl\/scalar:Lingy::Symbol
  =: prn
- !perl\/array:Lingy::List
  - !perl\/scalar:Lingy::Symbol
    =: \+
  - !perl\/scalar:Lingy::Number
    =: '2'
  - !perl\/scalar:Lingy::Number
    =: '3'/,
    "'\$cmd' produces correct YAML dump";

my $test = -d 't' ? 't' : 'test';

run_is "$lingy $test/program1.ly",
    "program: $ENV{PWD}/$test/program1.ly args: ()";

run_is "$lingy $test/program1.ly foo bar",
    "program: $ENV{PWD}/$test/program1.ly args: (foo bar)";

sub note_repl_input {
    note "Lingy REPL input: '$ENV{LINGY_TEST_INPUT}'";
}

{
    local $ENV{LINGY_TEST_INPUT} = '(prn *file* *command-line-args*)';
    note_repl_input;

    run_is "$lingy", qq<"NO_SOURCE_PATH" ()\nnil> if -t 0;
    run_is "$lingy --repl", qq<"NO_SOURCE_PATH" ()\nnil> if -t 0;

    run_is "$lingy --repl foo bar", qq<"NO_SOURCE_PATH" ("foo" "bar")\nnil>;

    local $ENV{LINGY_TEST_INPUT} = '(prn *file* *command-line-args* foo)';
    note_repl_input;

    run_is "$lingy -e '(def foo 42)' --repl", qq<"NO_SOURCE_PATH" () 42\nnil> if -t 0;

    run_is "$lingy -e '(def foo 42)'", 'user/foo';
}

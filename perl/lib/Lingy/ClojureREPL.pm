use strict; use warnings;
package Lingy::ClojureREPL;

use File::Which;
use IO::Select;
use IPC::Open3;
use Symbol 'gensym';
use Time::HiRes 'usleep';
use XXX;

my $done = '3416ebc19a42578b8ebc3f59ea1806266cea4290';
my $pid;
my ($in, $out, $err);
my ($select_out, $select_err);

my $Y = "\e[0;33m";
my $Z = "\e[0m";

my $clojure_jar;
my $already_searched = 0;
my $main_repl = <<'...';
(require '[clojure.main :as main])
(use 'clojure.repl
     ' clojure.pprint)
(apply main/repl [
  :prompt #()
  :caught (fn [e]
    (let [
      e-via (binding [ *data-readers* {'error identity} ] (let [ err-data (read-string (pr-str e))] (:via err-data)))
      [m1 m2 m3] e-via ]
      (if m1 (println (:message m1)))
      (if m2 (println (:message m2)))))])
...
# ...
my $server_opt =
    '-Dclojure.server.repl=' .
    '{:port 5555 :accept clojure.core.server/repl}';

sub start {
    my ($class, $newline) = @_;
    if (not $clojure_jar) {
        return if $already_searched++;
        my $file = which('clojure') or do {
            print "${Y}Can't find 'clojure' on this system$Z\n";
            return;
        };
        open my $fh, $file or
            die "Can't open '$file' for input: $!";
        my $text = do {local $/; <$fh>};
        $text =~ /java -cp +(.+?\.jar)/ or do {
            print "${Y}Can't find 'clojure' on this system$Z\n";
            return;
        };
        $clojure_jar = $1;
    }

    $pid = open3(
        $in,
        $out,
        $err = gensym,
        (
            'java', '-cp', $clojure_jar,
            $server_opt,
            'clojure.main',
            '-e', $main_repl,
        )
    );

    print "\n" if $newline;
    print "$Y*** Started Clojure REPL server ($pid)$Z\n\n";

    $select_out = new IO::Select();
    $select_out->add($out);
    $select_err = new IO::Select();
    $select_err->add($err);
}

sub rep {
    my ($class, $input) = @_;
    $class->start(1) unless $pid;
    return unless $pid;

    return if $input =~ /^\s*\(\s*clojure-repl-on\s*\)\s*$/;

    print $in qq<$input\n"$done"\n>;

    my $output = '';
    my $string = '';
    my $count = 0;
    my $rc = 0;

    usleep 500_000;
    while (1) {
        if ($select_out->can_read(0)) {
            sysread($out, $string, 4096);
            $output .= $string // '';
            last if $output =~ s/"$done"\n+//;
        }
        if ($select_err->can_read(0)) {
            sysread($err, $string, 4096);
            $output .= $string // '';
            last;
        }

        if (++$count >= 3) {
            $output = 'timeout';
            kill -9, $pid;
            print "$Y*** Killed Clojure REPL server ($pid)$Z\n";
            undef $pid;
            $rc = 255;
            last;
        }

        usleep 500_000;
    }

    chomp $output;

    print STDOUT "${Y}Clojure:$Z\n$output\n";
}

END {
    if (defined $pid) {
        print "$Y*** Stopping Clojure REPL server ($pid)$Z\n";
        print $in '(java.lang.System/exit 0)', "\n";
        waitpid( $pid, 0 );
        my $rc = $? >> 8;
        exit $rc unless $rc == 0;
    }
}

1;

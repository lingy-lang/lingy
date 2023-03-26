use strict; use warnings;
package Lingy::ReadLine;

BEGIN { $ENV{PERL_RL} = 'Gnu' }
use Term::ReadLine;

use Exporter 'import';

our @EXPORT = qw( readline );

my $history_file = "$ENV{HOME}/.lingy_history";

my $tty;
{
    local @ENV{qw(HOME EDITOR)};
    local $^W;
    $tty = Term::ReadLine->new('Lingy');
}

die "Please install Term::ReadLine::Gnu from CPAN\n"
    if $tty->ReadLine ne 'Term::ReadLine::Gnu';

sub readline {
    my $rt = $Lingy::Runtime::rt;

    my $prompt = $rt->prompt;
    my $env = $rt->env;

    $tty->ornaments(0);

    local $SIG{INT} = sub {
      print("\n");
      $tty->replace_line('', 0);
      $tty->on_new_line;
      $tty->redisplay;
    };

    if (not $ENV{LINGY_TEST}) {
        # These settings make the interactive repl nice to use but severely
        # slow down the self-hosting tests.
        $tty->parse_and_bind($_) for (
            'set blink-matching-paren on',
            'set show-all-if-ambiguous on',
        );
    }

    $tty->Attribs->{completion_function} = sub {
        my ($text, $line, $start) = @_;
        grep {not /^-/}
        keys %{$env->space}, qw(
            catch
            do
            false
            if
            macroexpand
            nil
            quasiquote
            quasiquoteexpand
            quote
            true
        );
        # Internal only: def! defmacro! fn* let* try* catch*
    };

    $tty->readline($prompt);
}

$tty->ReadHistory($history_file);

END {
    $tty->WriteHistory($history_file);
}

1;

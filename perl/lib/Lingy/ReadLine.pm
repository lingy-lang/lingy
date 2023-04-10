use strict; use warnings;
package Lingy::ReadLine;

BEGIN { $ENV{PERL_RL} = 'Gnu' }
use Term::ReadLine;

my $history_file = "$ENV{HOME}/.lingy_history";

my $tty;
{
    local @ENV{qw(HOME EDITOR)};
    local $^W;
    $tty = Term::ReadLine->new('Lingy');
}

die "Please install Term::ReadLine::Gnu from CPAN\n"
    if $tty->ReadLine ne 'Term::ReadLine::Gnu';

my $tested = 0;
sub readline {
    if (my $input = $ENV{LINGY_TEST_INPUT}) {
        return if $tested++;
        return $input;
    }

    my $prompt = $Lingy::RT::ns or die;
    $prompt .= '> ';

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

    $tty->Attribs->{completion_query_items} = 1000;
    $tty->Attribs->{completion_function} = sub {
        my ($text, $line, $start) = @_;
        return
            $Lingy::RT::env->space->names,
            (keys %Lingy::RT::class),
            qw(
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
    $tty->WriteHistory($history_file)
        unless $ENV{LINGY_TEST};
}

1;

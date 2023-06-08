use strict; use warnings;
package Lingy::ReadLine;

use Lingy::Common;

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
our $input;
sub readline {
    if (my $input = $ENV{LINGY_TEST_INPUT}) {
        return if $tested++;
        return $input;
    }

    my ($continue) = @_;

    my $prompt = RT->current_ns_name or die;
    if ($continue) {
        no warnings 'numeric';
        $prompt = (' ' x (length($prompt) - 2)) . '#_';
    }
    else {
        $input = '';
    }
    $prompt .= '=> ';

    $tty->ornaments(0);

    local $SIG{INT} = sub {
      print("\n");
      $tty->replace_line('', 0);
      $tty->on_new_line;
      $tty->redisplay;
    };

    $tty->parse_and_bind($_) for (
        'set blink-matching-paren on',
        'set show-all-if-ambiguous on',
    );

    $tty->Attribs->{completion_query_items} = 1000;
    $tty->Attribs->{completion_function} = \&complete;

    my $line = $tty->readline($prompt);
    return unless defined $line;
    $input .= $line;
    return $line;
}

sub complete {
    my ($text, $line, $start) = @_;

    if ($text =~ m{^(\w+(\.\w+)*)/}) {
        my $prefix = $1;
        if (my $ns = RT->namespaces->{$prefix}) {
            return map "$prefix/$_", keys %$ns;
        }
#         if (defined (my $class = RT->classes->{$prefix})) {
#             return map "$prefix/$_", $class->_method_names;
#         }
        return;
    }

    my $space = RT->env->{space};
    my @names =
        grep {not /^ /} (
            keys(%$space),
            keys(%{RT->namespaces}),
            map {
                my $name = $_;
                $name =~ s/^Lingy::/lingy.lang./;
                $name =~ s/::/./g;
                my $long = $name;
                $name =~ s/.*\.//;
                ($long, $name);
            } @{RT->class_names},
        );

    grep /^\Q$text/,
    map {
        /^-\w/ ? () :
        ($text eq '' and /^(\w+\.)/) ? $1 :
        $_
    } (
        @names,
        Lingy::Evaluator->special_symbols,
    );
}

$tty->ReadHistory($history_file);

END {
    $tty->WriteHistory($history_file)
        unless $ENV{LINGY_TEST};
}

1;

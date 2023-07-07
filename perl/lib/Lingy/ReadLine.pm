use strict; use warnings;
package Lingy::ReadLine;

use Lingy::Common;

BEGIN { $ENV{PERL_RL} = 'Gnu' }
use Term::ReadLine;

my $home = $ENV{HOME};

sub history_file {
    my $history_file = "$ENV{PWD}/.lingy_history";
    $history_file = "$home/.lingy_history"
        unless -w $history_file;
    return $history_file;
}

my $tty;
my $tested = 0;
my @input;
my $prev_input = '';
my $sep = "\x01";
my $readline_class;
my $multi = 0;

sub multi_start {}
sub multi_stop {}

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
}

sub setup {
    my ($self) = @_;

    local @ENV{qw(HOME EDITOR)};
    local $^W;
    undef $tty;
    $tty = Term::ReadLine->new('Lingy');

    die "Please install Term::ReadLine::Gnu from CPAN\n"
        if $tty->ReadLine ne 'Term::ReadLine::Gnu';

    $tty->ReadHistory($self->history_file);
    $tty->SetHistory(
        map {
            s/$sep/\n/g; $prev_input = $_;
        } $tty->GetHistory
    );
    $tty->MinLine(undef);

    return $self;
}

$SIG{TSTP} = sub {
    warn "\nCTL-Z disabled in this REPL\n";
};

sub input {
    return unless @input;
    my $input = join "\n", @input;
    if ($input =~ s/\ +\z//) {
        $input =~ s/\n/ /g;
    }
    if ($input =~ /\S/ and $input ne $prev_input) {
        $tty->addhistory($input);
        $prev_input = $input;
    }
    return $input;
}

sub readline {
    if (my $test_input = $ENV{LINGY_TEST_INPUT}) {
        return if $tested++;
        return $test_input;
    }

    my ($self, $continue) = @_;
    $readline_class = ref($self);

    my $prompt = RT->current_ns_name or die;
    if ($continue) {
        no warnings 'numeric';
        $prompt = (' ' x (length($prompt) - 2)) . '#_';
    }
    else {
        @input = ();
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
    $line =~ s/\s+\z// unless $line =~ /\ +\z/;
    push @input, $line;

    if ($self->multi_start($line)) {
        $prompt = (' ' x (length($prompt) - 5)) . '#_=> ';
        while (1) {
            my $more = $tty->readline($prompt);
            return unless defined $more;
            push @input, $more;
            $line .= "\n$more";
            last if $self->multi_stop($more);
        }
    }

    return $line;
}

sub complete {
    my ($text, $line, $start) = @_;

    if ($text =~ m{^(\w+(\.\w+)*)/}) {
        my $prefix = $1;
        if (my $ns = RT->namespaces->{$prefix}) {
            return map "$prefix/$_", keys %$ns;
        }
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

END {
    if ($readline_class) {
        $tty->SetHistory(map { s/\n/$sep/g; $_ } $tty->GetHistory);
        $tty->WriteHistory($readline_class->history_file)
            unless $ENV{LINGY_TEST};
    }
}

1;

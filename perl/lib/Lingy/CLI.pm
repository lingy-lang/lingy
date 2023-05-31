use strict; use warnings;

package Lingy::CLI;

use Getopt::Long;

use Lingy::Common;

use constant default => '--repl';
use constant options => +{
    repl        => 'bool',
    'clj|C'     => 'bool',
    'eval|e'    => 'str',
    run         => 'arg',
    ppp         => 'bool',
    xxx         => 'bool',
    version     => 'bool',
};

sub new {
    my $class = shift;

    bless {
        map( ($_, ''), keys %{$class->options} ),
        @_,
    }, $class;
}

sub main {
    require Lingy::Main;
    return Lingy::Main->new;
}

sub from_stdin {
    not -t STDIN or exists $ENV{LINGY_TEST_STDIN};
}

sub run {
    my ($self, @args) = @_;

    my $main = $self->main;

    $self->getopt(@args);

    my ($repl, $clj, $run, $eval, $ppp, $xxx, $args) =
        @{$self}{qw<repl clj run eval ppp xxx args>};
    local @ARGV = @$args;

    $main->init;

    if ($self->{version}) {
        $main->rep(
            '(println (str "Lingy [" *HOST* "] version " (lingy-version)))',
        );
        exit 0;
    }

    if ($clj) {
        $main->rep(qq<(clojure-repl-on)>);
    }

    if ($eval) {
        if ($repl) {
            $main->rep(qq<(do $eval\n)>);
            $main->repl;
        } else {
            if ($ppp) {
                $main->rep(qq<(PPP (quote $eval\n))>);
            } elsif ($xxx) {
                $main->rep(qq<(XXX (quote $eval\n))>);
            } else {
                unshift @ARGV, '-';
                map print("$_\n"),
                    grep $_ ne 'nil',
                    $main->rep($eval);
            }
        }

    } elsif ($repl) {
        $main->repl;

    } elsif ($run) {
        if ($run ne '/dev/stdin') {
            -f $run or err "No such file '$run'";
        }
        $main->rep(qq<(load-file "$run")>);

    } else {
        $main->repl;
    }
}

sub getopt {
    my ($self, @args) = @_;

    my $default = $self->default;

    if ($default and not(@args or $self->from_stdin)) {
        @args = ($default);
    }

    local @ARGV = @args;

    my $spec = {};
    my $opts = $self->options;
    for my $key (keys %$opts) {
        (my $name = $key) =~ s/\|.*//;
        my $type = $opts->{$key};
        if ($type eq 'bool') {
            $spec->{$key} = \$self->{$name};
        }
        elsif ($type eq 'str') {
            $spec->{"$key=s"} = \$self->{$name};
        }
        elsif ($type eq 'arg') {
        }
        else {
            err "Option type '$type' not supported";
        }
    }

    $spec->{help} = sub {
        print $ENV{LINGY_USAGE};
        exit 0;
    };

    Getopt::Long::Configure(qw(
        gnu_getopt
        no_auto_abbrev
        no_ignore_case
    ));
    eval {
      GetOptions (%$spec) or
          err "Error in command line arguments";
    };
    die "$@$ENV{LINGY_USAGE}" if $@;

    if (@ARGV) {
        if ($self->{repl}) {
            unshift @ARGV, 'NO_SOURCE_PATH';
        } else {
            $self->{run} = $ARGV[0];
            $self->{run} = '/dev/stdin'
                if $self->{run} eq '-';
        }

    } else {
        if ($self->from_stdin) {
            $self->{run} = '/dev/stdin';
            unshift @ARGV, '<stdin>';
        } else {
            unshift @ARGV, 'NO_SOURCE_PATH';
        }
    }

    $self->{args} = [@ARGV];
}

1;

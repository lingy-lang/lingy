use strict; use warnings;
package Lingy::Main;

use Lingy::RT;
use Lingy::Common;

use Getopt::Long;

use constant default => '--repl';
use constant options => +{
    'clj|C'     => 'bool',
    'dev|D'     => 'bool',
    'eval|e'    => 'str',
    ppp         => 'bool',
    repl        => 'bool',
    run         => 'arg',
    version     => 'bool',
    xxx         => 'bool',
};

sub new {
    my $class = shift;

    bless {
        map( ($_, ''), keys %{$class->options} ),
        @_,
    }, $class;
}

sub run {
    my ($self, @args) = @_;

    $self->getopt(@args);

    my ($repl, $run, $eval, $version, $clj, $dev, $args) =
        @{$self}{qw<repl run eval version clj dev args>};
    local @ARGV = @$args;

    RT->init;
    RT->rep(qq<(clojure-repl-on)>) if $clj;
    RT->rep(qq<(use 'lingy.devel)>) if $dev;

    $version ? $self->do_version() :
    $eval ? $self->do_eval() :
    $repl ? $self->do_repl() :
    $run ? $self->do_run() :
    $self->do_repl();
}

sub do_version {
    RT->rep(
        '(println (str "Lingy [" *HOST* "] version " (lingy-version)))',
    );
}

sub do_eval {
    my ($self) = @_;
    my ($repl, $eval, $ppp, $xxx) =
        @{$self}{qw<repl eval ppp xxx>};

    if ($repl) {
        RT->rep(qq<(do $eval\n)>);
        RT->repl;
    } else {
        if ($ppp) {
            RT->rep(qq<(use 'lingy.devel) (PPP (quote $eval\n))>);
        } elsif ($xxx) {
            RT->rep(qq<(use 'lingy.devel) (XXX (quote $eval\n))>);
        } else {
            unshift @ARGV, '-';
            map print("$_\n"),
                grep $_ ne 'nil',
                RT->rep($eval);
        }
    }
}

sub do_repl {
    RT->repl;
}

sub do_run {
    my ($self) = @_;
    my $run = $self->{run};
    if ($run ne '/dev/stdin') {
        -f $run or err "No such file '$run'";
    }
    RT->rep(qq<(load-file "$run")>);
}

sub from_stdin {
    not -t STDIN or exists $ENV{LINGY_TEST_STDIN};
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

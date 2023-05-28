use strict; use warnings;

package Lingy::CLI;

use Getopt::Long;

use Lingy::Common;

use constant default => '--repl';
use constant options => +{
    repl => 'bool',
    clj  => 'bool',
    eval => 'str',
    run  => 'arg',
    ppp  => 'bool',
    xxx  => 'bool',
};

sub new {
    my $class = shift;

    bless {
        map( ($_, ''), keys %{$class->options} ),
        @_,
    }, $class;
}

sub rt {
    require Lingy::RT;
    return Lingy::RT->new;
}

sub from_stdin {
    not -t STDIN or exists $ENV{LINGY_TEST_STDIN};
}

sub run {
    my ($self, @args) = @_;

    my $rt = $self->rt;

    $self->getopt(@args);

    my ($repl, $clj, $run, $eval, $ppp, $xxx, $args) =
        @{$self}{qw<repl clj run eval ppp xxx args>};
    local @ARGV = @$args;

    $rt->init;

    if ($clj) {
        $rt->rep(qq<(clojure-repl-on)>);
    }

    if ($eval) {
        if ($repl) {
            $rt->rep(qq<(do $eval\n)>);
            $rt->repl;
        } else {
            if ($ppp) {
                $rt->rep(qq<(PPP (quote $eval\n))>);
            } elsif ($xxx) {
                $rt->rep(qq<(XXX (quote $eval\n))>);
            } else {
                unshift @ARGV, '-';
                map print("$_\n"),
                    grep $_ ne 'nil',
                    $rt->rep($eval);
            }
        }

    } elsif ($repl) {
        $rt->repl;

    } elsif ($run) {
        if ($run ne '/dev/stdin') {
            -f $run or err "No such file '$run'";
        }
        $rt->rep(qq<(load-file "$run")>);

    } else {
        $rt->repl;
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
        my $type = $opts->{$key};
        if ($type eq 'bool') {
            $spec->{$key} = \$self->{$key};
        } elsif ($type eq 'str') {
            $spec->{"$key=s"} = \$self->{$key};
        } elsif ($type eq 'arg') {
        } else {
            err "Option type '$type' not supported";
        }
    }

    GetOptions (%$spec) or
        err "Error in command line arguments";

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

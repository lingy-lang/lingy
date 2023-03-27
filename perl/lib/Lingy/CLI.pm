use strict; use warnings;

package Lingy::CLI;

use Getopt::Long;

use Lingy::RT;
use Lingy::Common;

use constant default => '--repl';
use constant options => +{
    repl => 'bool',
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

sub from_stdin {
    not -t STDIN or exists $ENV{LINGY_TEST_STDIN};
}

sub run {
    my ($self, @args) = @_;

    $self->getopt(@args);

    my ($repl, $run, $eval, $ppp, $xxx, $args) =
        @{$self}{qw<repl run eval ppp xxx args>};
    local @ARGV = @$args;

    Lingy::RT->init;

    if ($eval) {
        if ($repl) {
            Lingy::RT->rep(qq<(do $eval\n)>);
            Lingy::RT->repl;
        } else {
            if ($ppp) {
                Lingy::RT->rep(qq<(PPP (quote $eval\n))>);
            } elsif ($xxx) {
                Lingy::RT->rep(qq<(XXX (quote $eval\n))>);
            } else {
                unshift @ARGV, '-';
                map print("$_\n"),
                    grep $_ ne 'nil',
                    Lingy::RT->rep($eval);
            }
        }

    } elsif ($repl) {
        Lingy::RT->repl;

    } elsif ($run) {
        if ($run ne '/dev/stdin') {
            -f $run or err "No such file '$run'";
        }
        Lingy::RT->rep(qq<(load-file "$run")>);

    } else {
        Lingy::RT->repl;
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

use strict; use warnings;

package Lingy::CLI;

use Getopt::Long;

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

    my $self = bless {
        map( ($_, ''), keys %{$class->options} ),
        @_,
    }, $class;

    $self->{runtime} = $self->runtime;

    return $self;
}

sub runtime {
    my ($self) = @_;
    my $runtime = ref($self) || $self;
    $runtime =~ s/::CLI$/::Runtime/ or
        die "Can't infer runtime class from '$runtime'";
    eval "use $runtime; 1" or
        die "Can't use '$runtime': $@";
    return $runtime;
}

sub from_stdin {
    not -t STDIN;
}

sub run {
    my ($self, @args) = @_;

    $self->getopt(@args);

    my ($runtime, $repl, $run, $eval, $ppp, $xxx, $args) =
        @{$self}{qw<runtime repl run eval ppp xxx args>};
    local @ARGV = @$args;

    if (@ARGV) {
        $run = $ARGV[0];
        $run = '/dev/stdin' if $run eq '-';

    } else {
        if ($self->from_stdin) {
            $run = '/dev/stdin';
            unshift @ARGV, '<stdin>';
        } else {
            unshift @ARGV, 'NO_SOURCE_PATH';
        }
    }

    if ($eval) {
        if ($repl) {
            my $runner = $runtime->new;
            $runner->rep(qq<(do $eval\n)>);
            $runner->repl;
        } else {
            if ($ppp) {
                $runtime->new->rep(qq<(PPP (quote $eval\n))>);
            } elsif ($xxx) {
                $runtime->new->rep(qq<(XXX (quote $eval\n))>);
            } else {
                unshift @ARGV, '-';
                $runtime->new->rep(qq<(do $eval\n)>);
            }
        }

    } elsif ($repl) {
        $runtime->new->repl;

    } elsif ($run) {
        if ($run ne '/dev/stdin') {
            -f $run or die "No such file '$run'";
        }
        $runtime->new->rep(qq<(load-file "$run")>);

    } else {
        $runtime->new->repl;
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
            die "Option type '$type' not supported";
        }
    }

    GetOptions (%$spec) or
        die "Error in command line arguments";

    $self->{args} = [@ARGV];
}

1;

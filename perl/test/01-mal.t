use strict; use warnings;

use Test::More;
use Capture::Tiny;

use lib 'lib';

use Lingy::REPL;
use Lingy::Printer;

my %plan = (
    2 => 14,
    3 => 28,
    4 => 186,
    5 => 4,
    6 => 41,
    7 => 143,
    8 => 54,
    9 => 138,
    10 => 89,
);

my @files = sort
    -d 'test' ? glob("test/mal/*") :
    -d 't' ? glob("t/mal/*") :
    die "Can't find test directory";

my $i = 1;
for my $file (@files) {
    my $repl = Lingy::REPL->new;

    $i++;
    # next unless $i == 6;
    # last if $i == 9;

    subtest $file => sub {
        plan tests => $plan{$i};

        for my $test (read_mal_test_file($file)) {
            my ($expr, $got, $want, $like, $out, $err);
            if (my $note = $test->{note}) {
                note $note;
            }
            ($out) = Capture::Tiny::capture {
                for (@{$test->{expr}}) {
                    $expr .= $_;
                    $got = eval { $repl->rep($_) };
                    if ($@) {
                        die $@ if $@ =~ /(^>>|^---\s| via package ")/;
                        $err .= ref($@)
                        ? "Error: " . Lingy::Printer::pr_str($@)
                        : $@;
                    }
                }
            };

#             ::XXX { expr=>$expr, got=>$got, want=>$want, like=>$like, out=>$out, err=>$err};

            chomp $expr;
            $expr =~ s/\n/\\n/g;

            if (my $like = $test->{like}) {
                $like = join '(?s:.*)', map {chomp; $_} @$like;
                $like = qr<^$like$>;

                if (defined $err) {
                    like $err, $like,
                        sprintf("e %-40s -> ERROR: '%s'", "'$expr'", $like);
                } else {
                    like $out, $like,
                        sprintf("o %-40s -> '%s'", "'$expr'", $like);
                }
            }

            if (length($got) and $want = $test->{want}) {
                $want = $want->[0];
                chomp $want;
                is $got, $want,
                    sprintf("%-40s -> '%s'", "'$expr'", $want);
            }
        }
    }
}

sub read_mal_test_file {
    my ($file) = @_;
    open IN, '<', $file or die "Can't open '$file' for input: $!";
    my @tests;

    my $t = {};
    while ($_ = <IN>) {
        if (s/^;; //) {
            chomp;
            $t->{note} = $_;
        } elsif (/(?:^;;|;>>>|^\s*$)/) {
        } elsif (s/^;\///) {
            my $like = $t->{like} //= [];
            push @$like, $_;

        } elsif (s/^;=>//) {
            my $want = $t->{want} //= [];
            push @$want, $_;

        } else {
            if ($t->{expr} and ($t->{like} or $t->{want})) {
                push @tests, $t;
                $t = {};
            }
            my $expr = $t->{expr} //= [];
            push @$expr, $_;
        }
    }
    push @tests, $t if $t->{expr};

    return @tests;
}

done_testing;

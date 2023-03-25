use strict; use warnings;

use Test::More;
use Capture::Tiny;

use lib 'lib';

use Lingy::Runtime;
use Lingy::Printer;

my %plan = (
    2 => 14,
    3 => 28,
    4 => 187,
    5 => 4,
    6 => 41,
    7 => 144,
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
    my $repl = Lingy::Runtime->new;

    $i++;
    # next unless $i == 6;
    # last if $i == 9;

    subtest $file => sub {
        plan tests => $plan{$i};

        my @tests = read_yaml_test_file($file);

        for my $test (@tests) {
            my ($expr, $got, $want, $like, $out, $err);
            if (my $note = $test->{note}) {
                note $note;
            }
            ($out) = Capture::Tiny::capture {
                for (@{$test->{expr}}) {
                    $expr .= $_;
                    my @got = eval { $repl->rep($_) };
                    if ($@) {
                        die $@ if $@ =~ /(^>>|^---\s| via package ")/;
                        $err .= ref($@)
                        ? "Error: " . Lingy::Printer::pr_str($@)
                        : $@;
                    }
                    $got = $got[0];
                }
            };

#             ::XXX { expr=>$expr, got=>$got, want=>$want, like=>$like, out=>$out, err=>$err};

            chomp $expr;
            $expr =~ s/\n/\\n/g;

            if (my $like = $test->{like}) {
                $like = join '(?s:.*)', map {chomp; $_} @$like;
                $like = qr<^$like$>;

                if (defined $err) {
                    chomp $err;
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

sub read_yaml_test_file {
    require YAML::PP;
    my ($file) = @_;

    my $tests = YAML::PP::LoadFile($file);

    map {
        my $t = {};
        $t->{note} = $_->{say} if defined $_->{say};
        $t->{expr} = ref($_->{mal}) ? $_->{mal} : [ $_->{mal} ]
            if defined $_->{mal};
        $t->{want} = ref($_->{out}) ? $_->{out} : [ $_->{out} ]
            if defined $_->{out};
        $t->{like} = ref($_->{err}) ? $_->{err} : [ $_->{err} ]
            if defined $_->{err};
        defined($t->{expr}) ? ($t) : ();
    } @$tests;
}

done_testing;

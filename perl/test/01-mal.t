use Lingy::Test;

my %plan = (
    2 => 14,    # 14
    3 => 28,    # 31
    4 => 187,   # 178
    5 => 4,     # 8
    6 => 55,    # 65
    7 => 144,   # 147
    8 => 54,    # 65
    9 => 137,   # 139
    A => 91,    # 108
);

my @files = sort
    -d 'test' ? glob("test/mal/*.yaml") :
    -d 't' ? glob("t/mal/*.yaml") :
    die "Can't find test directory";

if (my $step = $ENV{LINGY_TEST_MAL_STEP}) {
    @files = grep /$step/, @files;
}

my $runtime = Lingy::Main->init;

for my $file (@files) {
    $file =~ /step(.)/ or die;
    my $n = $1;

    subtest $file => sub {
        plan tests => $plan{$n};

        my @tests = read_yaml_test_file($file);

        for my $test (@tests) {
            my ($expr, $got, $want, $like, $out, $err);
            if (my $note = $test->{note}) {
                note $note;
            }
            ($out) = capture(
                sub {
                    for (@{$test->{expr}}) {
                        $expr .= $_;
                        my @got = eval { $runtime->rep($_) };
                        if ($@) {
                            die $@ if $@ =~ /(^>>|^---\s| via package ")/;
                            $err .= ref($@)
                            ? "Error: " . Lingy::Printer::pr_str($@)
                            : $@;
                        }
                        $got = $got[0];
                    }
                },
            );

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
            } elsif (defined $err and not $test->{eok}) {
                XXX $test, {
                    expr=>$expr,
                    got=>$got,
                    want=>$want,
                    like=>$like,
                    out=>$out,
                    err=>$err,
                };
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
        $t->{eok} = defined($_->{eok});
        defined($t->{expr}) ? ($t) : ();
    } @$tests;
}

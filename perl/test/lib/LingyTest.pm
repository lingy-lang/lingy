use strict; use warnings;
package LingyTest;

use Test::More;
use Capture::Tiny;
use IO::All;
use Lingy::Common;
use Lingy::RT;
use Lingy::Reader;
use Lingy::Printer;

my ($reader, $printer);

BEGIN {
    RT->init;
    $reader = Lingy::Reader->new;
    $printer = Lingy::Printer->new;
}

sub repl_test {
    my $tests = io(shift)->all;
    $tests =~ s/^#.*\n//mg;
    $tests =~ s/\A\s*//;
    my @tests = split /\n\n+/, $tests;
    for my $test (@tests) {
        $test .= "\n";
        if ($test =~ /\A; (.*)\n\z/) {
            note($1);
            next;
        }

        my $label = $test =~ s/\A; +(.+)\n// ? $1 : '';

        $test =~ s/\A([TP])=> (.*\n)// or parse_error($test);
        my $type = $1;
        my $input .= $2;
        $input .= $1 while $test =~ s/\A => (.*\n)//;
        chomp $input;

        my @result;
        undef $@;
        my ($stdout, $stderr) = Capture::Tiny::capture {
            eval {
                if ($type eq 'T') {
                    @result = RT->rep($input);
                } elsif ($type eq 'P') {
                    @result = $printer->pr_str($reader->read_str($input));
                } else { die }
            };
        };
        my $result = $@
            ? do { $_ = $@; chomp; $_ }
            : join "\n", @result;

        _test(' ', $label, \$test, $input, $result);
        _test('O', $label, \$test, $input, $stdout);
        _test('E', $label, \$test, $input, $stderr);

        die "Error running test:\n$test" if length $test;
    }
    done_testing();
}

sub _test {
    my ($pre, $label, $test, $input, $got) = @_;
    return unless length $got;
    my $tested = 0;
    while ($$test =~ s/^$pre(==|=~|~~) (.*)\n//m) {
        my ($op, $want) = ($1, $2);
        if ($op eq '==') {
            if (my @lines = ($$test =~ /^$pre== (.*)\n/gm)) {
                $$test =~ s/^$pre== (.*)\n//gm;
                $want .= "\n" . join "\n", @lines;
            }
            $label ||= "$input -> $want";
            $label =~ s/\n/\\n/g;

            is $got, $want, $label;
            $tested = 1;
        }
        elsif ($op eq '=~') {
            $label = $got;
            chomp $label;
            $label = "$input - Output" if length($label) > 40;
            $label .= " =~ /$want/";
            $label =~ s/\n/\\n/g;

            my $re = eval "qr/$want/" or die;
            like $got, $re, $label;
            $tested = 1;
        }
        else {
            die "Unknown test operator '$op'";
        }
    }
    die "Missing '$pre' test for: $label"
        if not $tested;
}

#         if (length $result) {
# 
#     while ($test =~ s/\A([ OE])(==|=~|~~) (.*\n)//) {
#         if ($2 eq '==') {
#             my $scalar =
#                 $1 eq ' ' ? 'r_eq' :
#                 $1 eq 'O' ? 'o_eq' :
#                 $1 eq 'E' ? 'e_eq' :
#                 die;
#             no strict 'refs';
#             $$scalar .= $3;
#         }
#         my $array =
#             $1 eq ' ' ? $2 eq '=~' ? 'r_match' : 'r_has' :
#             $1 eq 'O' ? $2 eq '=~' ? 'o_match' : 'o_has' :
#             $1 eq 'E' ? $2 eq '=~' ? 'e_match' : 'e_has' :
#             parse_error("$1$2 $3");
#         no strict 'refs';
#         push @$array, $3;
#     }
# }

sub parse_error {
    die "Invalid repl test format at:\n$_[0]";
}

# END { done_testing }

1;

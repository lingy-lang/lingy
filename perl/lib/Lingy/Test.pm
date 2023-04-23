use strict; use warnings;
package Lingy::Test;

use base 'Exporter';

use Test::More;

use Lingy::RT;
use Lingy::Common;

use Capture::Tiny qw'capture capture_merged';
use File::Temp 'tempfile';

use lib 'lib', './test/lib', './t/lib';

symlink 't', 'test' if -d 't' and not -e 'test';

our $rt = Lingy::RT->init;

$ENV{LINGY_TEST} = 1;

our $lingy =
    -f './blib/script/lingy' ? './blib/script/lingy' :
    -f './bin/lingy' ? './bin/lingy' :
    die "Can't find 'lingy' bin script to test";

our $eg =
    -d 'eg' ? 'eg' :
    -d 'example' ? 'example' :
    die "Can't find eg/example directory";

our @EXPORT = qw<
    done_testing
    is
    like
    note
    pass
    plan
    subtest
    use_ok

    capture
    capture_merged
    tempfile

    $lingy
    $rt
    $eg

    rep
    run_is
    test
    test_out

    PPP WWW XXX YYY ZZZ
>;

sub collapse;
sub line;

sub import {
    strict->import;
    warnings->import;
    shift->export_to_level(1, @_);
}

sub rep {
    $rt->rep(@_);
}

# Test 'rep' for return value or error:
sub test {
    my ($input, $want, $label) = @_;
    $label //= "'${\ collapse $input}' -> '${\line $want}'";

    my $got = eval { join("\n", $rt->rep($input)) };
    $got = $@ if $@;
    chomp $got;

    $got =~ s/^Error: //;

    if (ref($want) eq 'Regexp') {
        like $got, $want, $label;
    } else {
        is $got, $want, $label;
    }
}

sub test_out {
    my ($input, $want, $label) = @_;
    $label //= "'${\ collapse $input}' -> '${\line $want}'";
    my ($got) = Capture::Tiny::capture_merged {
        $rt->rep($input);
    };
    chomp $got;
    chomp $want;

    $got =~ s/^Error: //;

    if (ref($want) eq 'Regexp') {
        like $got, $want, $label;
    } else {
        is $got, $want, $label;
    }
}

sub run_is {
    my ($cmd, $want, $label) = @_;
    $label //= "'$cmd' -> '$want'";
    $label =~ s/\$cmd/$cmd/g;
    $label =~ s/\$want/$want/g;
    $label =~ s/\n/\\n/g;
    my $got = `( $cmd ) 2>&1`;
    chomp $got;
    if (ref($want) eq 'Regexp') {
        like $got, $want, $label;
    } else {
        chomp $got;
        is $got, $want, $label;
    }
}

sub collapse {
    local $_ = shift;
    s/\s\s+/ /g;
    s/^ //;
    chomp;
    $_;
}

sub line {
    local $_ = shift;
    s/\n/\\n/g;
    $_;
}

no warnings 'redefine';

my $done_testing = 0;
sub done_testing {
    return if $done_testing++;
    goto &Test::More::done_testing;
}

END {
    package main;
    done_testing();
}

1;

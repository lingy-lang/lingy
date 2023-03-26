use strict; use warnings;

package Lingy::Test;

use base 'Exporter';

use Test::More;

use Lingy::Runtime;
use Lingy::Printer;
use Lingy::Types;

use Capture::Tiny 'capture';
use File::Temp 'tempfile';

our $rt = Lingy::Runtime->new;

$ENV{LINGY_TEST} = 1;

our $lingy = './bin/lingy';

our @EXPORT = qw<
    done_testing
    is
    like
    note
    plan
    subtest

    capture
    tempfile

    $lingy
    $rt

    rep
    run_is
    test

    PPP WWW XXX YYY ZZZ
>;

sub import {
    strict->import;
    warnings->import;
    shift->export_to_level(1, @_);
}

sub rep {
    $rt->rep(@_);
}

sub test {
    my ($input, $want, $label) = @_;

    $label //= "'$input' -> '$want'";

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

sub run_is {
    my ($cmd, $want) = @_;
    my $got = `( $cmd ) 2>&1`;
    if (ref($want) eq 'Regexp') {
        like $got, $want, $cmd;
    } else {
        chomp $got;
        is $got, $want, $cmd;
    }
}

1;

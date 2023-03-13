#!/usr/bin/env perl

use strict; use warnings;

use Lingy::REPL;

use Getopt::Long;

@ARGV = ('--repl') unless (@ARGV or not -t STDIN);

my $repl = '';
my $eval = '';
my $run = '';
my $ppp = '';
my $xxx = '';

GetOptions (
    "repl" => \$repl,
    "eval=s" => \$eval,
    "ppp" => \$ppp,
    "xxx" => \$xxx,
) or die("Error in command line arguments\n");

if (@ARGV) {
    $run = $ARGV[0];
    $run = '/dev/stdin' if $run eq '-';
} else {
    if (not -t STDIN) {
        $run = '/dev/stdin';
        unshift @ARGV, '<stdin>';
    } else {
        unshift @ARGV, 'NO_SOURCE_PATH';
    }
}

if ($eval) {
    if ($repl) {
        Lingy::REPL->new->rep(qq<(do $eval)>);
        Lingy::REPL->new->repl;
    } else {
        if ($ppp) {
            Lingy::REPL->new->rep(qq<(PPP $eval)>);
        } elsif ($xxx) {
            Lingy::REPL->new->rep(qq<(XXX $eval)>);
        } else {
            unshift @ARGV, '-';
            Lingy::REPL->new->rep(qq<(prn (do $eval))>);
        }
    }

} elsif ($repl) {
    Lingy::REPL->new->repl;

} elsif ($run) {
    if ($run ne '/dev/stdin') {
        -f $run or die "No such file '$run'";
        $run =~ /\.ly$/ or
            die "Don't know how to run '$run'";
    }
    Lingy::REPL->new->rep(qq<(load-file "$run")>);

} else {
    Lingy::REPL->new->repl;
}

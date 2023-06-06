use strict; use warnings;
package Lingy::Util;

use Lingy::Common;

sub identical {
    BOOLEAN->new(refaddr($_[0]) == refaddr($_[1]));
}

#------------------------------------------------------------------------------
# Devel functions:
#------------------------------------------------------------------------------

sub applyTo {
    my ($method, $args) = @_;
    no strict 'refs';
    &{"$method"}(@$args);
}

sub eval_perl {
    my $ret = eval("$_[0]");
    $_[1] // $ret;
}

sub rt_internal { my $m = "$_[0]"; RT->$m }

sub env_data {
    my $env = $Lingy::Eval::ENV;
    my $www = {};
    my $w = $www;
    my $e = $env;
    while ($e) {
        $w->{'+'} = join ' ', sort CORE::keys %{$e->space};
        $w->{'^'} = {};
        $w = $w->{'^'};
        $e = $e->{outer};
    }
    bless $www, 'lingy-internal';
}

sub equiv {
    my ($x, $y) = @_;
    return false
        unless
            (
                $x->isa(LISTTYPE) and
                $y->isa(LISTTYPE)
            ) or ref($x) eq ref($y);
    if ($x->isa(LISTTYPE)) {
        return false unless @$x == @$y;
        for (my $i = 0; $i < @$x; $i++) {
            my $bool = equiv($x->[$i], $y->[$i]);
            return false if "$bool" eq '0';
        }
        return true;
    }
    if ($x->isa(HASHMAP)) {
        my @xkeys = sort map "$_", keys %$x;
        my @ykeys = sort map "$_", keys %$y;
        return false unless @xkeys == @ykeys;
        my @xvals = map $x->{$_}, @xkeys;
        my @yvals = map $y->{$_}, @ykeys;
        for (my $i = 0; $i < @xkeys; $i++) {
            return false unless "$xkeys[$i]" eq "$ykeys[$i]";
            my $bool = equiv($xvals[$i], $yvals[$i]);
            return false if "$bool" eq '0';
        }
        return true;
    }
    BOOLEAN->new($$x eq $$y);
}

1;

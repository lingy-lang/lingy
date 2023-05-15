use strict; use warnings;
package Lingy::Lang::Numbers;

use Lingy::Common;

use constant NAME => 'lingy.lang.Numbers';

sub add { $_[0] + $_[1] }

sub divide { $_[0] / $_[1] }

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
    boolean($$x eq $$y);
}

sub gt { $_[0] >  $_[1] }

sub gte { $_[0] >= $_[1] }

sub isPos { $_[0] > 0 }

sub isZero { ${$_[0]} == 0 }

sub lt { $_[0] <  $_[1] }

sub lte { $_[0] <= $_[1] }

sub minus { $_[0] - $_[1] }

sub multiply { $_[0] * $_[1] }

sub range {
    my ($start, $end, $step) = @_;
    if (not defined $end) {
        $end = $start;
        $start = number(0);
    }
    $step //= number(1);
    ($start, $end, $step) = ($$start, $$end, $$step);
    return list([]) if $step == 0;
    my @range;
    if ($step > 0) {
        return list([]) if $start > $end;
        while ($start < $end) {
            push @range, number($start);
            $start += $step;
        }
    } else {
        return list([]) if $start < $end;
        while ($start > $end) {
            push @range, number($start);
            $start += $step;
        }
    }
    list([@range]);
}

sub remainder {
    $_[0] % $_[1];
}

1;

use strict; use warnings;
package Lingy::Numbers;

use Lingy::Common;

use constant NAME => 'lingy.lang.Numbers';

sub add { $_[0] + $_[1] }

sub divide { $_[0] / $_[1] }

sub equiv { $_[0] == $_[1] }

sub gt { $_[0] > $_[1] }

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
        $start = NUMBER->new(0);
    }
    $step //= NUMBER->new(1);
    ($start, $end, $step) = ($$start, $$end, $$step);
    return list([]) if $step == 0;
    my @range;
    if ($step > 0) {
        return list([]) if $start > $end;
        while ($start < $end) {
            push @range, NUMBER->new($start);
            $start += $step;
        }
    } else {
        return list([]) if $start < $end;
        while ($start > $end) {
            push @range, NUMBER->new($start);
            $start += $step;
        }
    }
    list([@range]);
}

sub remainder {
    $_[0] % $_[1];
}

1;

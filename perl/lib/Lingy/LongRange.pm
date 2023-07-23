use strict; use warnings;
package Lingy::LongRange;

use Lingy::Common;

use base 'Lingy::Class';

use POSIX;

sub new {
    my ($class, $start, $end, $step, $count) = @_;
    bless {
        start => $start + 0,
        end   => $end + 0,
        step  => $step + 0,
        count => $count + 0,
    }, $class;
}

sub range_count {
    my ($start, $end, $step) = @_;
    int($end - $start + $step + (0 <=> $step) / $step);
}

sub create {
    my ($start, $end, $step) = @_;
    ($end, $start) = ($start, $end) if @_ == 1;
    $start //= 0;
    $end //= POSIX::LONG_MAX;
    $step //= 1;
    return LIST->EMPTY if
        ($step > 0 and $start > $end) or
        ($step < 0 and $end > $start);
    return REPEAT->create($start) if $step == 0;
    return LONGRANGE->new(
        $start,
        $end,
        $step,
        range_count($start, $end, $step),
    );
}

sub count {
    $_[0]->{count};
}

sub _to_seq {
    LAZYSEQ->new();
}

1;

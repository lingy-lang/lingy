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

sub create { no strict 'refs'; goto &{"_create_".@_} }

sub _create_1 {
    my ($end) = @_;
    return LIST->EMPTY if $end <= 0;
    return LONGRANGE->new(
        0, $end, 1,
        range_count(0, $end, 1),
    );
}

sub _create_2 {
    my ($start, $end) = @_;
    return LIST->EMPTY if $start >= $end;
    return LONGRANGE->new(
        $start, $end, 1,
        range_count($start, $end, 1),
    );
}

sub _create_3 {
    my ($start, $end, $step) = @_;
    return LIST->EMPTY if
        ($step > 0 and $start > $end) or
        ($step < 0 and $end > $start);
    return REPEAT->create($start) if $step == 0;
    return LONGRANGE->new(
        $start, $end, $step,
        range_count($start, $end, $step),
    );
}

sub count {
    $_[0]->{count};
}

sub _to_seq {
    XXX 42;
    LAZYSEQ->new();
}

1;

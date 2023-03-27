package Lingy::Lang::Numbers;

use Lingy::NS 'lingy.lang.Numbers';

use constant lingy_class => 'lingy.lang.Numbers';

sub equiv {
    my ($x, $y) = @_;
    return false
        unless
            ($x->isa('Lingy::Base::List') and $y->isa('Lingy::Base::List')) or
            (ref($x) eq ref($y));
    if ($x->isa('Lingy::Base::List')) {
        return false unless @$x == @$y;
        for (my $i = 0; $i < @$x; $i++) {
            my $bool = equiv($x->[$i], $y->[$i]);
            return false if "$bool" eq '0';
        }
        return true;
    }
    if ($x->isa('Lingy::Lang::HashMap')) {
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

our %ns = (
    fn('add'       => '2' => sub { $_[0] + $_[1] }),
    fn('minus'     => '2' => sub { $_[0] - $_[1] }),
    fn('multiply'  => '2' => sub { $_[0] * $_[1] }),
    fn('divide'    => '2' => sub { $_[0] / $_[1] }),

    fn('equiv'     => '2' => \&equiv),
    fn('lt'        => '2' => sub { $_[0] <  $_[1] }),
    fn('lte'       => '2' => sub { $_[0] <= $_[1] }),
    fn('gt'        => '2' => sub { $_[0] >  $_[1] }),
    fn('gte'       => '2' => sub { $_[0] >= $_[1] }),
);

sub isZero {
    ${$_[0]} == 0;
}

sub remainder {
    $_[0] % $_[1];
}

1;

package Lingy::Lang::BaseList;

use base 'Lingy::Lang::Base';

sub new {
    my ($class, $list) = @_;
    bless $list, $class;
}

sub clone { ref($_[0])->new([@{$_[0]}]) }

1;

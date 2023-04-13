use strict; use warnings;
package Lingy::Lang::Class;

sub _lingy_class_name {
    my ($self) = @_;
    my $class = ref($self) or die;
    $class =~ s/^Lingy::Lang::/lingy.lang./;
    return $class;
}

1;

use strict; use warnings;
package Lingy::Lang::Class;

use Lingy::Common();
my %common = map {($_, 1)} @Lingy::Common::EXPORT;

sub _lingy_class_name {
    my ($self) = @_;
    my $class = ref($self) or die;
    $class =~ s/^Lingy::Lang::/lingy.lang./;
    return $class;
}

sub _method_names {
    my ($self) = @_;
    my $class = ref($self) || $self;
    no strict 'refs';
    grep {
        not(
            exists($common{$_}) or
            /(^_|^[A-Z]+$|can|import|isa|new)/
        )
    } keys %{"$class\::"};
}

1;

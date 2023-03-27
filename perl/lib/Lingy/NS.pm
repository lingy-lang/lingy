use strict; use warnings;
package Lingy::NS;

use Lingy::Common;

sub new {
    my $class = shift;
    no strict 'refs';
    bless \%{"${class}::ns"}, $class;
}

sub init {
    my ($self) = @_;
    (my $key = ref($self) . '.pm') =~ s{::}{/}g;
    (my $file = $INC{$key}) =~ s/\.pm$/.ly/;
    RT->rep(slurp($file)) if -f $file;
}

sub name {
    my ($self) = @_;
    my $name = ref($self);
    $name =~ s/::/./g;
    $name =~ s/^Lingy\./lingy./;
    return $name;
}

1;

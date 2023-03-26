use strict; use warnings;
package Lingy::NS;

use Lingy::Common;

sub init {
    my ($self) = @_;
    (my $key = ref($self) . '.pm') =~ s{::}{/}g;
    (my $file = $INC{$key}) =~ s/\.pm$/.ly/;
    RT->rep(slurp($file)) if -f $file;
}

1;

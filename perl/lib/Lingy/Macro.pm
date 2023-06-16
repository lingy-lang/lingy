use strict; use warnings;
package Lingy::Macro;

use base 'Lingy::Class';

use Lingy::Common;

sub new {
    my ($class, $function) = @_;
    XXX $function unless ref($function) eq FUNCTION;
    bless sub { goto &$function }, $class;
}

1;

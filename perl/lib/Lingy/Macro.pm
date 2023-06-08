use strict; use warnings;
package Lingy::Macro;

use Lingy::Common;

sub new {
    my ($class, $function) = @_;
    XXX $function unless ref($function) eq FUNCTION;
    bless sub { goto &$function }, $class;
}

1;

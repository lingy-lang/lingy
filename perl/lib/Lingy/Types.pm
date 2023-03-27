use strict; use warnings;
package Lingy::Types;

package
macro;
# use base 'function';
sub new {
    my ($class, $function) = @_;
    XXX $function unless ref($function) eq 'Lingy::Lang::Function';
    bless sub { goto &$function }, $class;
}

1;

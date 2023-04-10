package Lingy::Lang::Macro;

use Lingy::Lang::Base;

sub new {
    my ($class, $function) = @_;
    XXX $function unless ref($function) eq 'Lingy::Lang::Function';
    bless sub { goto &$function }, $class;
}

1;

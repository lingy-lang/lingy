package Lingy::Compiler::YAML;
use Lingy::Base;
extends 'Lingy::Compiler';

use YAML::XS;

sub compile {
    my ($self, $input) = @_;
    YAML::XS::Load($input);
}

1;

package Lingy::Emitter::YAML;
use Pegex::Base;
extends 'Lingy::Emitter';

use YAML::XS;

sub emit {
    my ($self, $ast) = @_;
    YAML::XS::Dump($ast);
}

1;

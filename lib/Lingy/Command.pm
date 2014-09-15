package Lingy::Command;
use Lingy::Base;

sub run {
    my ($args) = @_;
    local @ARGV = @$args;
}

1;

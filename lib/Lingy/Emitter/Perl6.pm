package Lingy::Emitter::Perl6;
use Lingy::Base;
extends 'Lingy::Emitter';

sub emit_class_head {
    my ($self, $name, $body) = @_;
    <<"...";
class $name;

...
}

sub emit_method_head {
    my ($self, $name, $body) = @_;
    my $arg_list = join ', ', map {
        my ($var, $type) = each %$_;
        "\$$var";
    } @{$body->args};
    my $out = <<"...";
method $name($arg_list) {
...
}

sub emit_method_foot {
    my ($self, $name, $body) = @_;
    "}\n";
}

# XXX This needs to be implemented (just faked it):
sub emit_statement {
    my ($self, $statement) = @_;
    qq{  say 'Hello ' ~ \$name;\n};
}

1;


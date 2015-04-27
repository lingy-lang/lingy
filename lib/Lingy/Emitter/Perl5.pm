package Lingy::Emitter::Perl5;
use Lingy::Base;
extends 'Lingy::Emitter';

sub emit_module_head {
    my ($self, $name, $body) = @_;
    shift;
    my $out = $self->SUPER::emit_module_head(@_) .
        "use strict; use warnings; use utf8;\n\n";
}

sub emit_module_foot {
    my ($self, $name, $body) = @_;
    "1;\n";
}

sub emit_class_head {
    my ($self, $name, $body) = @_;
    <<"...";
package $name;
use Moose;

...
}

sub emit_method_head {
    my ($self, $name, $body) = @_;
    my $arg_list = join ', ', map {
        my ($var, $type) = each %$_;
        "\$$var";
    } @{$body->args};
    $arg_list = ", $arg_list" if $arg_list;
    my $out = <<"...";
sub $name {
  my (\$self$arg_list) = \@_;
...
}

sub emit_method_foot {
    my ($self, $name, $body) = @_;
    "};\n";
}

# XXX This needs to be implemented (just faked it):
sub emit_statement {
    my ($self, $statement) = @_;
    qq{  print(('Hello ' . \$name) . "\\n");\n};
}

1;


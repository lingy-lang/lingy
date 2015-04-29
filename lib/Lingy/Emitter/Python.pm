package Lingy::Emitter::Python;
use Lingy::Base;
extends 'Lingy::Emitter';

sub emit_class_head {
    my ($self, $name, $body) = @_;
    <<"...";
class $name():

...
}

sub emit_method {
    my ($self, $name, $body) = @_;
    shift;
    my $out = $self->SUPER::emit_method(@_);
    $out =~ s/^/  /gm;
    return $out;
}

sub emit_method_head {
    my ($self, $name, $body) = @_;
    my $arg_list = join ', ', map {
        my ($var, $type) = each %$_;
        "$var";
    } @{$body->args};
    $arg_list = ", $arg_list" if $arg_list;
    my $out = <<"...";
def $name(self$arg_list):
...
}

# XXX This needs to be implemented (just faked it):
sub emit_statement {
    my ($self, $statement) = @_;
    qq{  print 'Hello ' + name\n};
}

1;


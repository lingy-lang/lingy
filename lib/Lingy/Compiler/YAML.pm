package Lingy::Compiler::YAML;
use Lingy::Base;
extends 'Lingy::Compiler';

has file => ();
has text => ();
# XXX should be inherited from Lingy::Compiler.
has ast => sub { Lingy::AST->new };

use YAML::XS;

sub BUILD {
    my ($self) = shift;
    die "Lingy Compiler requires 'text' or 'file' attribute"
        unless $self->{text} or $self->{file};
}

sub compile {
    my ($self, $input) = @_;
    my $code = $self->{code} = YAML::XS::Load($input);
    my $ast = $self->ast;
    my $module = $ast->module;
    $module->{name} = $code->{name}
        or die "Unknown name for Lingy Module";
    for my $class (@{$code->{class}}) {
        push @{$module->{class}}, $self->compile_class($class);
    }
    return $ast;
}

sub compile_class {
    my ($self, $code) = @_;
    my $class = Lingy::Class->new;
    my $methods = $code->{meth} || [];
    for my $next (@$methods) {
        my ($name, $method) = each %$next;
        push @{$class->method}, $name;
        $class->stash->{$name} = $self->compile_method($method);
    }
    $class->{name} = $code->{name};
    return $class;
}

sub compile_method {
    my ($self, $code) = @_;
    Lingy::Method->new(
        args => $code->{args},
        rets => $code->{rets},
        code => $code->{code},
    );
}


sub get_input {
    my ($self) = @_;
    if ($self->{text}) {
        return $self->{text};
    }
    else {
        my $file = $self->{file}
            or die "No input for compile";
        open my $fh, $file
            or die "Can't open '$file' for input";
        local $/;
        return <$fh>;
    }
}

1;

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
    my ($self) = @_;
    my $input = $self->get_input;
    my $code = $self->{code} = YAML::XS::Load($input);
    $code->{type} eq 'Module'
        or die "Unknown Lingy type: '$code->{type}'";
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
    XXX $code;
    my $class = Lingy::Class->new;
    $class->{name} = $code->{name};
    return $class;
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

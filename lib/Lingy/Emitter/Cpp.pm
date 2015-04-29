package Lingy::Emitter::Cpp;
use Lingy::Base;
extends 'Lingy::Emitter';

sub emit_module_head {
    my ($self, $name, $body) = @_;
    shift;
    my $out = 
        "#include <iostream>\n#include <string>\n";
}

sub emit_module_foot {
    my ($self, $name, $body) = @_;
    <<"EOM";
EOM
}

sub emit_class_head {
    my ($self, $name, $body) = @_;
    <<"...";
class $name {
public:

...
}

sub emit_class_foot {
    "};\n"
}

my %cpp_types = (
    Str => 'std::string',
);
my %cpp_return = (
    Nul => 'void',
);

sub emit_method_head {
    my ($self, $name, $body) = @_;
    my $arg_list = join ', ', map {
        my ($var, $type) = each %$_;
        "$cpp_types{ $type } $var";
    } @{ $body->args };
    my $rets = $body->rets;
    my $out = <<"...";
$cpp_return{ $rets } $name ($arg_list) {
...
}

sub emit_method_foot {
    my ($self, $name, $body) = @_;
    "}\n";
}

# XXX This needs to be implemented (just faked it):
sub emit_statement {
    my ($self, $statement) = @_;
    my ($cmd, $args) = @{ $statement };
    if ($cmd eq 'IO/say') {
        return qq{    std::cout << "Hello " << name << "\\n";\n};
    }
    else {
        return qq{    std::cout << "Not implemented\\n";\n};
    }
}

1;


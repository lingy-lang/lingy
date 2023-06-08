use strict; use warnings;
package Lingy::Namespace;

use Lingy::Common;

use Sub::Name 'subname';

has '_name';

sub new {
    my $class = shift;
    my $name = shift;

    # XXX Could be a HashMap
    my $self = bless {'_name' => $name, @_}, __PACKAGE__;

    return RT->namespaces->{$name} = $self;
}

sub refer {
    my ($self, $refer_ns_name) = @_;
    err "'refer' only works with symbols"
        unless ref($refer_ns_name) eq SYMBOL;
    my $refer_ns = RT->namespaces->{$$refer_ns_name}
        or err "No namespace: '$$refer_ns_name'";
    map $self->{$_} = $refer_ns->{$_},
        grep not(/^_/), keys %$refer_ns;
    $self->{$refer_ns_name} = $refer_ns;
    return $self;
}

sub current {
    my ($self) = @_;
    my $name = $self->_name or die;
    RT->current_ns_name($name);
    RT->namespaces->{$name} = $self;
    RT->env->{space} = $self;
    # RT->namespaces->{'lingy.core'}{'*ns*'} = $self;
    return $self;
}

sub set {
    my ($self, $symbol, $value) = @_;
    $self->{$symbol} = $value;
    return symbol($self->_name . "/$symbol");
}

sub getName {
    symbol($_[0]->_name);
}

sub getImports {
    XXX @_, 'TODO - getImports';
}

sub getInterns {
    my $map = {
        %{$_[0]},
    };
    delete $map->{'_name'};
    HASHMAP->new([ %$map ]);
}

sub getMappings {
    my %map = %{$_[0]};
    delete $map{'_name'};
    HASHMAP->new([ %map ]);
}

1;

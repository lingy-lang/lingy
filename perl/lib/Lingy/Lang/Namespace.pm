use strict; use warnings;
package Lingy::Lang::Namespace;

use Lingy::Common;

use Sub::Name 'subname';

sub NAME {
    my ($self) = @_;
    $self->{' NAME'} // '';
}

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, __PACKAGE__;

    my $name = $self->{' NAME'} = $args{name};

    if (my $refer_list = $args{refer}) {
        $refer_list = [$refer_list]
            unless ref($refer_list) eq 'ARRAY';
        my $refer_map = RT->ns_refers->{$name} //= {};
        for my $ns (@$refer_list) {
            my $ns_name = $ns->NAME;
            map $refer_map->{$_} = $ns_name,
                grep /^\S/, keys %$ns;
        }
    }

    no strict 'refs';
    no warnings 'once';
    if (%{"${class}::ns"}) {
        %$self = (
            %$self,
            %{"${class}::ns"},
        );
    }

    RT->namespaces->{$name} = $self;

    return $self;
}

sub current {
    my ($self) = @_;
    my $name = $self->NAME or die;
    RT->current_ns_name($name);
    RT->namespaces->{$name} = $self;
    RT->env->{space} = $self;
    RT->namespaces->{'lingy.core'}{'*ns*'} = $self;
    return $self;
}

sub getName {
    symbol($_[0]->NAME);
}

sub getImports {
    XXX @_, 'TODO - getImports';
}

sub getInterns {
    my $map = {
        %{$_[0]},
    };
    delete $map->{' NAME'};
    HASHMAP->new([ %$map ]);
}

sub getMappings {
    my $map = {
        %{$_[0]},
    };
    my $name = delete $map->{' NAME'};
    my $refer = RT->ns_refers->{$name} // {};
    for my $key (keys %$refer) {
        my $ns = $refer->{$key};
        $map->{$key} =
            RT->namespaces->{$ns}->{$key} //
            RT->namespaces->{$key};
    }
    HASHMAP->new([ %$map ]);
}

1;

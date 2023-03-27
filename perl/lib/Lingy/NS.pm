use strict; use warnings;
package Lingy::NS;

use base 'Exporter';

use Lingy::Common;

use Sub::Name 'subname';

@Lingy::NS::EXPORT = (
    'fn',
    'slurp',
    @Lingy::Common::EXPORT,
);

sub name { shift->{' NAME'} }

sub import {
    my ($pkg, $name) = @_;
    strict->import;
    warnings->import;
    {
        my $caller = caller;
        no strict 'refs';
        no warnings 'redefine';
        push @{"${caller}::ISA"}, $pkg;
        *{"${caller}::name"} = sub { $name };
    }
    $pkg->export_to_level(1);
}

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    my $name = $self->{' NAME'} = $args{name} // $self->name;

    if (my $refer_list = $args{refer}) {
        $refer_list = [$refer_list]
            unless ref($refer_list) eq 'ARRAY';
        my $refer_map = $Lingy::RT::refer{$name} //= {};
        for my $ns_name (@$refer_list) {
            my $ns = $Lingy::RT::ns{$ns_name} or die;
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

    $self->load unless $args{delay};

    $Lingy::RT::ns{$name} = $self;

    return $self;
}

sub load {
    my ($self) = @_;
    (my $key = ref($self) . '.pm') =~ s{::}{/}g;
    (my $file = $INC{$key} // '') =~ s/\.pm$/.ly/;
    Lingy::RT->rep(slurp($file)) if -f $file;
}

sub current {
    my ($self) = @_;
    my $name = $self->name or die;
    $Lingy::RT::ns = $name;
    $Lingy::RT::ns{$name} = $self;
    $Lingy::RT::env->{space} = $self;
    $Lingy::RT::ns{'lingy.core'}{'*ns*'} = $self;
    return $self;
}

sub names {
    my ($self) = @_;
    my %names;
    map {$names{$_} = 1}
        grep {not /^ /}
        keys(%$self),
        keys(%Lingy::RT::ns),
        keys(%{$Lingy::RT::refer{$self->name}});
    return keys %names;
}

sub fn {
    my ($name, %functions) = @_;
    (
        $name,
        subname "fn::$name" => sub {
            my $arity = @_;
            my $function =
                $functions{$arity} ||
                $functions{'*'}
                    or err "Wrong number of args ($arity) passed to function";
            $function->(@_);
        }
    );
}

sub slurp {
    my ($file) = @_;
    open my $slurp, '<', "$file" or
        err "Couldn't read file '$file'";
    local $/;
    <$slurp>;
}

1;

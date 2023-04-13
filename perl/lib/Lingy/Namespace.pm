use strict; use warnings;
package Lingy::Namespace;

use Lingy::Common;

use base 'Exporter';

use Sub::Name 'subname';

our @EXPORT = (
    'fn',
);

sub name {
    my ($self) = @_;
    $self->{' NAME'} // '';
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

    $self->_load_ly_file;

    $Lingy::RT::ns{$name} = $self;

    return $self;
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

sub _load_ly_file {
    my ($self) = @_;
    (my $key = ref($self) . '.pm') =~ s{::}{/}g;
    (my $file = $INC{$key} // '') =~ s/\.pm$/.ly/;
    Lingy::RT->rep(Lingy::RT::slurp($file)) if -f $file;
    return $self;
}

1;

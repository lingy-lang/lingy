use strict; use warnings;
package Lingy::Env;

use Lingy::Types;

sub space { shift->{space} }

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        outer => $args{outer},
        space => $args{space} // {},
    }, $class;
    my $binds = [ @{$args{binds} // []} ];
    my $exprs = $args{exprs} // [];
    while (@$binds) {
        if ("$binds->[0]" eq '&') {
            shift @$binds;
            $exprs = [list([@$exprs])];
        }
        $self->set(shift(@$binds), shift(@$exprs) // nil);
    }
    return $self;
}

sub set {
    my ($self, $key, $val) = @_;
    $self->{space}{$key} = $val;
}

sub get {
    my ($self, $key) = @_;

    while ($self) {
        if (defined(my $val = $self->{space}{$key})) {
            return $val;
        }
        $self = $self->{outer};
    }

    err "Unable to resolve symbol: $key in this context";
}

sub is_macro_call {
    my ($self, $ast) = @_;

    my $name;
    return unless
        ref($ast) eq 'list' and
        $name = $ast->[0] and
        ref($name) eq "symbol";

    my $val;
    while ($self and not defined($val = $self->{space}{$$name})) {
        $self = $self->{outer};
    }

    $self and ref($val) eq 'macro';
}

1;

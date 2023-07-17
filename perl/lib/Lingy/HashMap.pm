use strict; use warnings;
package Lingy::HashMap;

use base 'immutable::map', 'Lingy::Class';

use Lingy::Common;

sub new {
    my ($class, $data) = @_;
    my (@keys, %vals);

    if (ref($data) eq 'HASH') {
        @keys = keys %$data;
        %vals = %$data;
    }
    elsif (ref($data) eq 'ARRAY') {
        for (my $i = @$data - 2; $i >= 0; $i -= 2) {
            my $key = $class->_get_key($data->[$i]);
            if (not exists $vals{$key}) {
                unshift @keys, $key;
                $vals{$key} = $data->[$i + 1];
            }
        }
    }
    else {
        die "Argument must be a reference to a hash or an array.\n";
    }

    my @data = map { ($_, $vals{$_}) } @keys;
    my $self = $class->SUPER::new(@data);
    return $self;
}

sub unbox {
    my @list = %{$_[0]};
    my $hash = {};
    for (my $i = 0; $i < @list; $i += 2) {
        my $key = $list[$i];
        $key =~ s/^"//;
        $hash->{$key} = $list[$i+1]->unbox;
    }
    return $hash;
}

sub clone {
    $_[0]->set();
}

sub assoc {
    my ($self, $key, $val) = @_;
    $key = $self->_get_key($key);
    my $new = $self->set($key, $val);
    $new;
}

sub _get_key {
    my ($self, $key) = @_;
    my $type = ref($key);
    $type eq '' ? qq<$key> :
    $type eq STRING ? qq<"$key> :
    $type eq SYMBOL ? qq<$key > :
    $type->isa(SCALARTYPE) ? qq<$key> :
    (   # Quoted symbol:
        $type eq LIST and
        ref($key->[0]) eq SYMBOL and
        ${$key->[0]} eq 'quote' and
        ref($key->[1]) eq SYMBOL
    ) ? ${$key->[1]} . ' ' :
    err "Type '$type' not supported as a hash-map key";
}

sub _to_seq {
    my ($map) = @_;
    return nil unless %$map;
    LIST->new([
        map {
            my $val = $map->{$_};
            my $key =
                s/^"// ? STRING->new($_) :
                s/^(\S+) $/$1/ ? SYMBOL->new($_) :
                s/^:// ? KEYWORD->new($_) :
                m/^\d+$/ ? NUMBER->new($_) :
                XXX $_;
            VECTOR->new([$key, $val]);
        } keys %{$_[0]}
    ]);
}

1;

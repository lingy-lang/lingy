use strict; use warnings;
package Lingy::HashSet;

use base 'Lingy::Class';

use Lingy::Common;

use Hash::Ordered;

sub new {
    my ($class, $list) = @_;
    tie my %hash, 'Hash::Ordered';
    for (my $i = 0; $i < @$list; $i++) {
        my $val = $list->[$i];
        my $key = $class->_get_key($val);
        delete $hash{$key} if exists $hash{$key};
        $hash{$key} = $val;
    }
    bless \%hash, $class;
}

sub clone {
    HASHSET->new([ %{$_[0]} ]);
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
            $map->{$_};
        } keys %{$_[0]}
    ]);
}

1;

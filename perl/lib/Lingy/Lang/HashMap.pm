use strict; use warnings;
package Lingy::Lang::HashMap;

use Lingy::Common;
use base CLASS;

use Tie::IxHash;

*err = \&Lingy::Common::err;

sub new {
    my ($class, $list) = @_;
    my %hash;
    my $tie = tie(%hash, 'Tie::IxHash');
    my $hash = \%hash;
    for (my $i = 0; $i < @$list; $i += 2) {
        my $key = $class->_get_key($list->[$i]);
        delete $hash->{$key} if exists $hash->{$key};
        $hash->{$key} = $list->[$i + 1];
    }
    bless $hash, $class;
}

sub clone {
    hash_map([ %{$_[0]} ]);
}

sub assoc {
    my ($self, $key, $val) = @_;
    my $new = $self->clone;
    $key = $self->_get_key($key);
    $new->{$key} = $val;
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
    list([
        map {
            my $val = $map->{$_};
            my $key =
                s/^"// ? string($_) :
                s/^(\S+) $/$1/ ? symbol($_) :
                s/^:// ? keyword($_) :
                m/^\d+$/ ? number($_) :
                XXX $_;
            vector([$key, $val]);
        } keys %{$_[0]}
    ]);
}

1;

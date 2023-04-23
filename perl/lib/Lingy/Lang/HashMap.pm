use strict; use warnings;
package Lingy::Lang::HashMap;

use base 'Lingy::Lang::Class';
use Lingy::Common;

use Tie::IxHash;

*err = \&Lingy::Common::err;

sub new {
    my ($class, $list) = @_;
    for (my $i = 0; $i < @$list; $i += 2) {
        my $key = $list->[$i];
        my $type = ref($key);
        $list->[$i] =
            $type eq '' ? qq<$key> :
            $type eq 'Lingy::Lang::String' ? qq<"$key> :
            $type eq 'Lingy::Lang::Symbol' ? qq<$key > :
            $type->isa('Lingy::Lang::ScalarClass') ? qq<$key> :
            (   # Quoted symbol:
                $type eq 'Lingy::Lang::List' and
                ref($key->[0]) eq 'Lingy::Lang::Symbol' and
                ${$key->[0]} eq 'quote' and
                ref($key->[1]) eq 'Lingy::Lang::Symbol'
            ) ? ${$key->[1]} . ' ' :
            err "Type '$type' not supported as a hash-map key";
    }
    my %hash;
    my $tie = tie(%hash, 'Tie::IxHash', @$list);
    my $hash = \%hash;
    bless $hash, $class;
}

sub clone {
    hash_map([ %{$_[0]} ]);
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

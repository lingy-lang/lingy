package Lingy::Lang::HashMap;

use Lingy::Lang::Base;

use Tie::IxHash;
use Lingy::Common();

*err = \&Lingy::Common::err;

sub new {
    my ($class, $list) = @_;
    for (my $i = 0; $i < @$list; $i += 2) {
        my $key = $list->[$i];
        if (my $type = ref($key)) {
            err "Type '$type' not supported as a hash-map key"
                if not($key->isa('Lingy::Lang::BaseScalar')) or $type eq 'Lingy::Lang::Symbol';
            $list->[$i] = $type eq 'Lingy::Lang::String'
                ? qq<"$key>
                : qq<$key>;
        }
    }
    my %hash;
    my $tie = tie(%hash, 'Tie::IxHash', @$list);
    my $hash = \%hash;
    bless $hash, $class;
}

sub clone {
    hash_map([ %{$_[0]} ]);
}

1;

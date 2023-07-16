use strict; use warnings;
package LingyBencode;

use Lingy::Common;

use Bencode;

sub bencode {
    my ($map) = @_;
    my $hash = $map->unbox;
    my $bencoded = Bencode::bencode($hash);
    STRING->new($bencoded);
}

1;

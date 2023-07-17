use strict; use warnings;
package LingyBencode;

use Lingy::Common;
use Data::Dumper;

use Bencode;

sub bencode {
    my ($map) = @_;
    my $hash = $map->unbox;
    my $bencoded = Bencode::bencode($hash);
    STRING->new($bencoded);
}

sub bdecode {
    my ($string) = @_;
    my $bdecoded = Bencode::bdecode($string);
    HASHMAP->new($bdecoded);
}


1;

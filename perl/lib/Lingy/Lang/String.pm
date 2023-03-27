package Lingy::Lang::String;

use Lingy::Base 'Scalar';

use constant lingy_class => 'host.lang.String';

sub replaceAll {
    my ($str, $pat, $rep) = @_;
    $str =~ s/\Q$pat\E/$rep/g;
    string($str);
}

sub toUpperCase {
    string(uc $_[0]);
}

1;

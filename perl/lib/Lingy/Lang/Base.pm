use strict; use warnings;
package Lingy::Lang::Base;

use base 'Exporter';

use Lingy::Common;

use Lingy::Lang::BaseList;
use Lingy::Lang::BaseScalar;

BEGIN {
    @Lingy::Lang::Base::EXPORT = @Lingy::Common::EXPORT;
}

sub import {
    my ($pkg, $base) = @_;
    strict->import;
    warnings->import;
    if ($base) {
        my $caller = caller;
        no strict 'refs';
        unshift @{"${caller}::ISA"}, "Lingy::Lang::Base";
        unshift @{"${caller}::ISA"}, "Lingy::Lang::Base$base";
    } else {
        my $caller = caller;
        no strict 'refs';
        unshift @{"${caller}::ISA"}, "Lingy::Lang::Base";
    }
    @_ = ($pkg);
    goto &Exporter::import;
}

sub lingy_class {
    my ($self) = @_;
    my $class = ref($self) or die;
    $class =~ s/^Lingy::Lang::/lingy.lang./;
    return $class;
}

1;

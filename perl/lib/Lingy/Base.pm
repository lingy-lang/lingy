use strict; use warnings;
package Lingy::Base;

use base 'Exporter';

use Lingy::Common;

use Lingy::Base::List;
use Lingy::Base::Map;
use Lingy::Base::Scalar;

BEGIN {
    @Lingy::Base::EXPORT = @Lingy::Common::EXPORT;
}

sub import {
    my ($pkg, $base) = @_;
    strict->import;
    warnings->import;
    if ($base) {
        my $caller = caller;
        no strict 'refs';
        unshift @{"${caller}::ISA"}, "Lingy::Base::$base";
    }
    @_ = ($pkg);
    goto &Exporter::import;
}

1;

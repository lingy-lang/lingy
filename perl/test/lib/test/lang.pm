use strict; use warnings;
package test::lang;

use Lingy::Namespace;
use base 'Lingy::Namespace';
use Lingy::Common;

use constant NAME => 'test.lang';

our %ns = (
    fn(foo => '0' => sub { string "called test.lang/foo" }),
);

1;

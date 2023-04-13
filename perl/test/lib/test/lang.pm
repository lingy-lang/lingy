use strict; use warnings;
package test::lang;

use constant name => 'test.name';

use Lingy::Namespace;
use base 'Lingy::Namespace';
use Lingy::Common;

our %ns = (
    fn(foo => '0' => sub { string "called test.lang/foo" }),
);

1;

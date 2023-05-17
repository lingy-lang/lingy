use strict; use warnings;
package Foo::Bar;

use Lingy::Namespace;
use base 'Lingy::Namespace';
use constant NAME => 'Foo.Bar';

our %ns = (
    fn('foo' => 0 => sub { 123 }),
);

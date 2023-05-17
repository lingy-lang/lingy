use strict; use warnings;
package Foo::Bar;

use Lingy::Common;
use Lingy::Namespace;
use base 'Lingy::Namespace';

use constant NAME => 'Foo.Bar';
use constant CLASSNAME => 'Foo.Bar';

sub foo {
    return number(42);
}

1;

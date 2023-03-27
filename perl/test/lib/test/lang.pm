package test::lang;

use Lingy::NS 'test.lang';

our %ns = (
    fn(foo => '0' => sub { string "called test.lang/foo" }),
);

1;

package test::lang;

use Lingy::Namespace;

our %ns = (
    fn(foo => '0' => sub { string "called test.lang/foo" }),
);

1;

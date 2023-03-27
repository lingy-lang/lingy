package Lingy::Lang::Keyword;

use Lingy::Base 'Scalar';

use constant lingy_class => 'host.lang.Keyword';

sub new {
    my ($class, $scalar) = @_;
    $scalar =~ s/^://;
    $scalar = ":$scalar";
    bless \$scalar, $class;
}

1;

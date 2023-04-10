package Lingy::Lang::Keyword;

use Lingy::Lang::Base 'Scalar';

sub new {
    my ($class, $scalar) = @_;
    $scalar =~ s/^://;
    $scalar = ":$scalar";
    bless \$scalar, $class;
}

1;

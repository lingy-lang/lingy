use Lingy::Test;

use Lingy::Reader;
use Lingy::Printer;

my $reader = Lingy::Reader->new;
my $printer = Lingy::Printer->new;

sub tst {
    my ($str, $want) = @_;
    my ($got) = Lingy::Printer::pr_str($reader->read_str($str));
    is $got, $want, "'$str' -> '$want'";
}

tst '42',
    '42';

# tst 'foo#',
#     'x';

done_testing;

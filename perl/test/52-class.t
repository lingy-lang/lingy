use Lingy::Test;

use lib './test/lib';

test "(class? lingy.lang.Number)",
     'true';

test "(class? lingy.core)",
     "Class not found: 'lingy.core'";

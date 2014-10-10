#------------------------------------------------------------------------------
package Lingy::AST;
use Lingy::Base;

has module => sub { Lingy::Module->new };

#------------------------------------------------------------------------------
package Lingy::Module;
use Lingy::Base;

has class => [];
has name => ();

#------------------------------------------------------------------------------
package Lingy::Class;
use Lingy::Base;

# Class can be anonymous, but typically is defined with a name:
has name => ();
# Methods, attributes, class variables:
has namespace => {};
# The parent class (for inheritance):
has parent => ();
# The (names of) attributes defined by the class:
has attribute => [];
# The (names of) methods defined by the class:
has method => [];

#------------------------------------------------------------------------------
package Lingy::Stash;
use Lingy::Base;

has namespace => {};

#------------------------------------------------------------------------------
package Lingy::Function;
use Lingy::Base;

has name => ();
has signature => {};
has namespace => {};
has statement => [];

#------------------------------------------------------------------------------
package Lingy::Method;
use Lingy::Base;
extends 'Lingy::Function';

#------------------------------------------------------------------------------
package Lingy::Signature;
use Lingy::Base;

#------------------------------------------------------------------------------
package Lingy::Attribute;
use Lingy::Base;

#------------------------------------------------------------------------------
package Lingy::Statement;
use Lingy::Base;

#------------------------------------------------------------------------------
package Lingy::Assignment;
use Lingy::Base;
extends 'Lingy::Statement';

#------------------------------------------------------------------------------
package Lingy::Expression;
use Lingy::Base;

#------------------------------------------------------------------------------
# Base class for all data type classes
#------------------------------------------------------------------------------
package Lingy::Object;
use Lingy::Base;

has type => sub { die };
has value => ();

#------------------------------------------------------------------------------
package Lingy::Symbol;
use Lingy::Base;
extends 'Lingy::Object';

use constant type => 'Sym';

#------------------------------------------------------------------------------
package Lingy::String;
use Lingy::Base;
extends 'Lingy::Object';

use constant type => 'Str';

#------------------------------------------------------------------------------
package Lingy::Number;
use Lingy::Base;
extends 'Lingy::Object';

use constant type => 'Num';

#------------------------------------------------------------------------------
package Lingy::Boolean;
use Lingy::Base;
extends 'Lingy::Object';

use constant type => 'Bool';

#------------------------------------------------------------------------------
package Lingy::Null;
use Lingy::Base;
extends 'Lingy::Object';

use constant type => 'Null';

1;

#------------------------------------------------------------------------------
package Lingy::AST;
use Lingy::Base;

#------------------------------------------------------------------------------
package Lingy::Module;
use Lingy::Base;

has class => [];

#------------------------------------------------------------------------------
package Lingy::Class;
use Lingy::Base;

has name => ();
has namespace => ();

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
package Lingy::Expr;
use Lingy::Base;

#------------------------------------------------------------------------------
package Lingy::Assign;
use Lingy::Base;

#------------------------------------------------------------------------------
# Base class for all data type classes
#------------------------------------------------------------------------------
package Lingy::Data;
use Lingy::Base;

has type => sub { die };
has value => ();

#------------------------------------------------------------------------------
package Lingy::Symbol;
use Lingy::Base;
extends 'Lingy::Data';

use constant type => 'Sym';

#------------------------------------------------------------------------------
package Lingy::String;
use Lingy::Base;
extends 'Lingy::Data';

use constant type => 'Str';

#------------------------------------------------------------------------------
package Lingy::Number;
use Lingy::Base;
extends 'Lingy::Data';

use constant type => 'Num';

#------------------------------------------------------------------------------
package Lingy::Boolean;
use Lingy::Base;
extends 'Lingy::Data';

use constant type => 'Bool';

#------------------------------------------------------------------------------
package Lingy::Null;
use Lingy::Base;
extends 'Lingy::Data';

use constant type => 'Null';

1;

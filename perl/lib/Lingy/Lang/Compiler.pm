use strict; use warnings;
package Lingy::Lang::Compiler;

use Lingy::Common;

use constant DEF            => symbol('def');
use constant LOOP           => symbol('loop*');
use constant RECUR          => symbol('recur');
use constant IF             => symbol('if');
use constant CASE           => symbol('case*');
use constant LET            => symbol('let*');
use constant LETFN          => symbol('letfn*');
use constant DO             => symbol('do');
use constant FN             => symbol('fn*');
use constant QUOTE          => symbol('quote');
use constant THE_VAR        => symbol('var');
use constant IMPORT         => symbol('import*');
use constant DOT            => symbol('.');
use constant ASSIGN         => symbol('set!');
use constant DEFTYPE        => symbol('deftype*');
use constant REIFY          => symbol('reify*');
### TRY_FINALLY
use constant TRY            => symbol('try');
use constant THROW          => symbol('throw');
use constant MONITOR_ENTER  => symbol('monitor-enter');
use constant MONITOR_EXIT   => symbol('monitor-exit');
### INSTANCE
### IDENTICAL
### THISFN
use constant CATCH          => symbol('catch');
use constant FINALLY        => symbol('finally');
### CLASS
use constant NEW            => symbol('new');
### UNQUOTE
### UNQUOTE_SPLICING
### SYNTAX_QUOTE
use constant _AMP_          => symbol('&');


use constant specials => hash_map([
        DEF,            nil,
        LOOP,           nil,    # change to loop*
        RECUR,          nil,
        IF,             nil,
        LET,            nil,
#         LETFN,          nil,
        DO,             nil,
        FN,             nil,
        QUOTE,          nil,
        THE_VAR,        nil,
        IMPORT,         nil,
        DOT,            nil,
#         ASSIGN,         nil,
#         DEFTYPE,        nil,
#         REIFY,          nil,
        TRY,            nil,
        THROW,          nil,
#         MONITOR_ENTER,  nil,
#         MONITOR_EXIT,   nil,
        CATCH,          nil,
#         FINALLY,        nil,
#         NEW,            nil,      # TODO make special
#         _AMP_,          nil,

# TODO Maybe add these:
### UNQUOTE
### UNQUOTE_SPLICING
### SYNTAX_QUOTE
]);

1;

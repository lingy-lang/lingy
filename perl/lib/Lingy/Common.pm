use strict; use warnings;
package Lingy::Common;

use Exporter 'import';

use constant SCALARTYPE => 'Lingy::Lang::ScalarClass';
use constant LISTTYPE   => 'Lingy::Lang::ListClass';

use constant NUMBERS    => 'Lingy::Lang::Numbers';
use constant RT         => 'Lingy::Lang::RT';
use constant TERM       => 'Lingy::Lang::Term';
use constant THREAD     => 'Lingy::Lang::Thread';

use constant ATOM       => 'Lingy::Lang::Atom';
use constant BOOLEAN    => 'Lingy::Lang::Boolean';
use constant CHARACTER  => 'Lingy::Lang::Character';
use constant CLASS      => 'Lingy::Lang::Class';
use constant COMPILER   => 'Lingy::Lang::Compiler';
use constant FUNCTION   => 'Lingy::Lang::Function';
use constant HASHMAP    => 'Lingy::Lang::HashMap';
use constant KEYWORD    => 'Lingy::Lang::Keyword';
use constant LIST       => 'Lingy::Lang::List';
use constant MACRO      => 'Lingy::Lang::Macro';
use constant NIL        => 'Lingy::Lang::Nil';
use constant NUMBER     => 'Lingy::Lang::Number';
use constant REGEX      => 'Lingy::Lang::Regex';
use constant STRING     => 'Lingy::Lang::String';
use constant SYMBOL     => 'Lingy::Lang::Symbol';
use constant VECTOR     => 'Lingy::Lang::Vector';
use constant VAR        => 'Lingy::Lang::Var';

BEGIN {
    our @EXPORT = qw<
        READY
        $symbol_re
        $namespace_re

        SCALARTYPE
        LISTTYPE

        COMPILER
        NUMBERS
        RT
        TERM
        THREAD

        atom        ATOM
        boolean     BOOLEAN
        char        CHARACTER
        class       CLASS
        function    FUNCTION
        hash_map    HASHMAP
        keyword     KEYWORD
        list        LIST
        macro       MACRO
        nil         NIL
        number      NUMBER
        regex       REGEX
        string      STRING
        symbol      SYMBOL
        var         VAR
        vector      VECTOR

        err
        assert_args
        comp_pair
        false
        true

        PPP
        WWW
        XXX
        YYY
        ZZZ
    >;
}

use Lingy::Printer;

our $namespace_re = qr{^(?:
    \w+
    (?:\.\w+)*
)}x;

our $symbol_re = qr{^(
    \*?[-\w]+[\?\!\*\#]? |
    [-+*/<>] |
    ==? |
    <= |
    >=|
    ->>?
)}x;

sub READY { $Lingy::Main::ready // 0 }


sub atom     { ATOM->new(@_) }
sub boolean  { BOOLEAN->new(@_) }
sub char     { CHARACTER->read(@_) }
sub class    { CLASS->_new(@_) }
sub function { FUNCTION->new(@_) }
sub keyword  { KEYWORD->new(@_) }
sub hash_map { HASHMAP->new(@_) }
sub list     { LIST->new(@_) }
sub macro    { MACRO->new(@_) }
sub number   { NUMBER->new(@_) }
sub regex    { REGEX->new(@_) }
sub string   { STRING->new(@_) }
sub symbol   { SYMBOL->new(@_) }
sub var      { VAR->new(@_) }
sub vector   { VECTOR->new(@_) }

sub err {
    my $msg = shift;
    $msg = sprintf $msg, @_;
    die "Error:" .
        ($msg =~ /\n./ ? "\n" : ' ') .
        $msg .
        "\n";
}

sub assert_args {
    my $args = shift;
    for (my $i = 0; $i < @_; $i++) {
        if (ref($args->[$i]) ne $_[$i]) {
            my (undef, undef, undef, $fn) = caller(1);
            err "Arg %d for '%s' must be '%s', not '%s'",
                $i, $fn, $_[$i], ref($args->[$i]);
        }
    }
}

sub comp_pair {
    my ($x, $y) = @_;
    if (ref($x) eq NIL) {
        return ref($y) eq NIL ? 0 : -1;
    }
    return 1 if ref($y) eq NIL;
    ref($x) eq ref($y) or
        err "Can't compare values of type '%s' and '%s'",
            ref($x), ref($y);
    if (ref($x) eq VECTOR) {
        return @$x cmp @$y unless @$x == @$y;
        my $i = 0;
        for my $e (@$x) {
            return 1 if $i > @$y;
            my $r = comp_pair $x->[$i], $y->[$i];
            return $r if $r;
            $i++;
        }
        return 0;
    }
    "$x" cmp "$y";
}

sub PPP {
    require Lingy::Printer;
    die _dump(Lingy::Printer::pr_str(@_));
}
sub WWW {
    warn _dump(@_);
    return wantarray ? @_ : $_[0];
}
sub XXX {
    die _dump(@_);
}
sub YYY {
    print _dump(@_);
    return wantarray ? @_ : $_[0];
}
sub ZZZ {
    require Carp;
    Carp::confess _dump(@_);
}
sub _dump {
    require YAML::PP;
    YAML::PP->new(
        schema => ['Core', 'Perl', '-dumpcode']
    )->dump_string(@_) . "...\n";
}

1;

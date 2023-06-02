use strict; use warnings;
package Lingy::Common;

use Exporter 'import';

use Scalar::Util 'refaddr';

# Base type classes:
use constant LISTTYPE   => 'Lingy::Lang::ListClass';
use constant SCALARTYPE => 'Lingy::Lang::ScalarClass';
use constant SEQUENTIAL => 'Lingy::Lang::Sequential';

# Type classes:
use constant ATOM       => 'Lingy::Lang::Atom';
use constant BOOLEAN    => 'Lingy::Lang::Boolean';
use constant CHARACTER  => 'Lingy::Lang::Character';
use constant CLASS      => 'Lingy::Lang::Class';
use constant COMPILER   => 'Lingy::Lang::Compiler';
use constant FUNCTION   => 'Lingy::Lang::Fn';
use constant HASHMAP    => 'Lingy::Lang::HashMap';
use constant KEYWORD    => 'Lingy::Lang::Keyword';
use constant LIST       => 'Lingy::Lang::List';
use constant MACRO      => 'Lingy::Lang::Macro';
use constant NIL        => 'Lingy::Lang::Nil';
use constant NUMBER     => 'Lingy::Lang::Number';
use constant REGEX      => 'Lingy::Lang::Regex';
use constant STRING     => 'Lingy::Lang::String';
use constant SYMBOL     => 'Lingy::Lang::Symbol';
use constant UTIL       => 'Lingy::Lang::Util';
use constant VECTOR     => 'Lingy::Lang::Vector';
use constant VAR        => 'Lingy::Lang::Var';

# Functionality classes:
use constant NAMESPACE  => 'Lingy::Lang::Namespace';
use constant NUMBERS    => 'Lingy::Lang::Numbers';
use constant RT         => 'Lingy::Lang::RT';
use constant TERM       => 'Lingy::Lang::Term';
use constant THREAD     => 'Lingy::Lang::Thread';

BEGIN {
    our @EXPORT = qw<
        READY

        $symbol_re
        $namespace_re

        refaddr

        LISTTYPE
        SCALARTYPE
        SEQUENTIAL

        COMPILER
        NAMESPACE
        NUMBERS
        RT
        TERM
        THREAD
        UTIL

        ATOM
        BOOLEAN
        CHARACTER
        CLASS
        FUNCTION
        HASHMAP
        KEYWORD
        LIST
        MACRO
        NIL
        NUMBER
        REGEX
        STRING
        SYMBOL
        VAR
        VECTOR

        list
        string
        symbol

        err
        assert_args
        comp_pair
        nil
        false
        true

        Dump
        PPP
        WWW
        XXX
        YYY
        ZZZ
    >;
}

use Lingy::Printer;

our $namespace_re = qr{(?:
    \w+
    (?:\.\w+)*
)}x;

our $symbol_re = qr{(
    \*?[-\w]+[\?\!\*\#]? |
    [-+*/<>] |
    ==? |
    <= |
    >=|
    ->>?
)}x;

sub READY { RT->ready }

sub list     { LIST->new(@_) }
sub string   { STRING->new(@_) }
sub symbol   { SYMBOL->new(@_) }

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

sub Dump {
    _dump(@_);
}
sub PPP {
    require Lingy::Printer;
    die _dump(RT->printer->pr_str(@_));
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

use strict; use warnings;
package Lingy::Common;

use Exporter 'import';

use Scalar::Util 'refaddr';

# Base type classes:
use constant LISTTYPE   => 'Lingy::ListClass';
use constant SCALARTYPE => 'Lingy::ScalarClass';
use constant SEQUENTIAL => 'Lingy::Sequential';

# Type classes:
use constant ATOM       => 'Lingy::Atom';
use constant BOOLEAN    => 'Lingy::Boolean';
use constant CHARACTER  => 'Lingy::Character';
use constant CLASS      => 'Lingy::Class';
use constant COMPILER   => 'Lingy::Compiler';
use constant FUNCTION   => 'Lingy::Fn';
use constant HASHMAP    => 'Lingy::HashMap';
use constant KEYWORD    => 'Lingy::Keyword';
use constant LIST       => 'Lingy::List';
use constant MACRO      => 'Lingy::Macro';
use constant NIL        => 'Lingy::Nil';
use constant NUMBER     => 'Lingy::Number';
use constant REGEX      => 'Lingy::Regex';
use constant STRING     => 'Lingy::String';
use constant SYMBOL     => 'Lingy::Symbol';
use constant UTIL       => 'Lingy::Util';
use constant VECTOR     => 'Lingy::Vector';
use constant VAR        => 'Lingy::Var';

# Functionality classes:
use constant NAMESPACE  => 'Lingy::Namespace';
use constant NUMBERS    => 'Lingy::Numbers';
use constant RT         => 'Lingy::RT';
use constant TERM       => 'Lingy::Term';
use constant THREAD     => 'Lingy::Thread';

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

        has
        err
        box_val
        unbox_val
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

{
    my ($n, $t, $f);
    ($n, $t, $f) = (1, 1, 0);
    my $nil = bless \$n, 'Lingy::Nil';
    my $true = bless \$t, BOOLEAN;
    my $false = bless \$f, BOOLEAN;
    sub nil { $nil }
    sub true { $true }
    sub false { $false }
}

our $namespace_re = qr{(?:
    \w+
    (?:\.\w+)*
)}x;

our $symbol_re = qr{(
    \*?[-\w]+[\?\!\*\#\=]? |
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

sub has {
    my ($caller) = caller;
    my $name = shift;
    my $method =
        sub {
            $#_
                ? $_[0]{$name} = $_[1]
                : $_[0]{$name};
        };
    no strict 'refs';
    *{"${caller}::$name"} = $method;
};

sub err {
    my $msg = shift;
    $msg = sprintf $msg, @_;

    # XXX This is needed to keep the mal tests passing for now.
    if ($ENV{LINGY_TEST}) {
        $msg = "Error:" .
            ($msg =~ /\n./ ? "\n" : ' ') .
            $msg;
    }

    die "$msg\n";
}

sub box_val {
    map {
        my $o = $_;
        my $type = ref($o);
        if (not($type)) {
            /^\-?\d+$/ ? NUMBER->new($o) : STRING->new($o);
        }
        elsif ($type =~ /^(?:ARRAY|HASH|SCALAR|REF|Regexp)$/) {
            XXX $o, "Lingy can't box this object yet";
        } else {
            $o;
        }
    } @_;
}

sub unbox_val {
    my ($obj) = @_;
    ref($obj) =~ /^Lingy::(String|Number|Boolean|Fn)$/ ? $obj->unbox : $obj;
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
            my $r = comp_pair($x->[$i], $y->[$i]);
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

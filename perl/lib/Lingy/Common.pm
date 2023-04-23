use strict; use warnings;
package Lingy::Common;

use Exporter 'import';

BEGIN {
    our @EXPORT = qw<
        READY
        $symbol_re

        atom
        boolean
        char
        class
        false
        function
        hash_map
        keyword
        list
        macro
        nil
        number
        regex
        string
        symbol
        true
        var
        vector

        err
        comp_pair

        PPP
        WWW
        XXX
        YYY
        ZZZ
    >;
}

use Lingy::Printer;

our $symbol_re = qr{^(
    \*?[-\w]+[\?\!\*\#]? |
    [-+*/<>] |
    ==? |
    <= |
    >=|
    ->>?
)}x;

sub READY { $Lingy::RT::ready // 0 }

sub atom     { Lingy::Lang::Atom->new(@_) }
sub boolean  { Lingy::Lang::Boolean->new(@_) }
sub char     { Lingy::Lang::Character->read(@_) }
sub class    { Lingy::Lang::Class->_new(@_) }
sub function { Lingy::Lang::Function->new(@_) }
sub keyword  { Lingy::Lang::Keyword->new(@_) }
sub hash_map { Lingy::Lang::HashMap->new(@_) }
sub list     { Lingy::Lang::List->new(@_) }
sub macro    { Lingy::Lang::Macro->new(@_) }
sub number   { Lingy::Lang::Number->new(@_) }
sub regex    { Lingy::Lang::Regex->new(@_) }
sub string   { Lingy::Lang::String->new(@_) }
sub symbol   { Lingy::Lang::Symbol->new(@_) }
sub var      { Lingy::Lang::Var->new(@_) }
sub vector   { Lingy::Lang::Vector->new(@_) }

sub err {
    my $msg = shift;
    $msg = sprintf $msg, @_;
    die "Error:" .
        ($msg =~ /\n./ ? "\n" : ' ') .
        $msg .
        "\n";
}

sub comp_pair {
    my ($x, $y) = @_;
    if (ref($x) eq 'Lingy::Lang::Nil') {
        return ref($y) eq 'Lingy::Lang::Nil' ? 0 : -1;
    }
    return 1 if ref($y) eq 'Lingy::Lang::Nil';
    ref($x) eq ref($y) or
        err "Can't compare values of type '%s' and '%s'",
            ref($x), ref($y);
    if (ref($x) eq 'Lingy::Lang::Vector') {
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

use strict; use warnings;
package Lingy::Common;

use Exporter 'import';

BEGIN {
    our @EXPORT = qw<
        atom
        boolean
        false
        function
        hash_map
        keyword
        list
        macro
        nil
        number
        string
        symbol
        true
        type
        var
        vector

        err

        PPP
        WWW
        XXX
        YYY
        ZZZ
    >;
}

use Lingy::Printer;

sub atom     { Lingy::Lang::Atom->new(@_) }
sub boolean  { Lingy::Lang::Boolean->new(@_) }
sub function { Lingy::Lang::Function->new(@_) }
sub keyword  { Lingy::Lang::Keyword->new(@_) }
sub hash_map { Lingy::Lang::HashMap->new(@_) }
sub list     { Lingy::Lang::List->new(@_) }
sub macro    { Lingy::Lang::Macro->new(@_) }
sub number   { Lingy::Lang::Number->new(@_) }
sub string   { Lingy::Lang::String->new(@_) }
sub symbol   { Lingy::Lang::Symbol->new(@_) }
sub type     { Lingy::Lang::Type->new(@_) }
sub var      { Lingy::Lang::Var->new(@_) }
sub vector   { Lingy::Lang::Vector->new(@_) }

sub err {
    my $msg = shift;
    die "Error:" .
        ($msg =~ /\n./ ? "\n" : ' ') .
        $msg .
        "\n";
}

sub PPP {
    require Lingy::Printer;
    XXX(Lingy::Printer::pr_str(@_));
}
sub WWW { require XXX; goto &XXX::WWW }
sub XXX { require XXX; goto &XXX::XXX }
sub YYY { require XXX; goto &XXX::YYY }
sub ZZZ { require XXX; goto &XXX::ZZZ }

1;

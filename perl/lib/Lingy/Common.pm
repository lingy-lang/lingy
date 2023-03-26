use strict; use warnings;
package Lingy::Common;

use Exporter 'import';

use Lingy::Types;

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
    vector

    RT
    err
    fn
    slurp

    PPP
    WWW
    XXX
    YYY
    ZZZ
>;

sub atom     { 'atom'    ->new(@_) }
sub boolean  { 'boolean' ->new(@_) }
sub function { 'function'->new(@_) }
sub keyword  { 'keyword' ->new(@_) }
sub hash_map { 'hash_map'->new(@_) }
sub list     { 'list'    ->new(@_) }
sub macro    { 'macro'   ->new(@_) }
sub number   { 'number'  ->new(@_) }
sub string   { 'string'  ->new(@_) }
sub symbol   { 'symbol'  ->new(@_) }
sub vector   { 'vector'  ->new(@_) }

sub RT { $Lingy::Runtime::rt }

sub err {
    my $msg = shift;
    die "Error:" .
        ($msg =~ /\n./ ? "\n" : ' ') .
        $msg .
        "\n";
}

sub fn {
    my $functions = {@_};
    sub {
        my $arity = @_;
        my $function =
            $functions->{$arity} ||
            $functions->{'*'}
                or err "Wrong number of args ($arity) passed to function";
        $function->(@_);
    }
}

sub slurp {
    my ($file) = @_;
    open my $slurp, '<', "$file" or
        err "Couldn't read file '$file'";
    local $/;
    <$slurp>;
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

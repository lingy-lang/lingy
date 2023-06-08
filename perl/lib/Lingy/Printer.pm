use strict; use warnings;
package Lingy::Printer;

use Lingy::Common;

use Scalar::Util 'blessed';
use Sub::Identify 'sub_name';

sub new { bless {}, shift }

my $escape = {
    "\n" => "\\n",
    "\t" => "\\t",
    "\"" => "\\\"",
    "\\" => "\\\\",
};

sub pr_str {
    my ($self, $o, $raw) = (@_, 0);
    $o //= '';
    my $type = ref $o;

    # Hack to allow map key strings to print like symbols:
    if (not $type and $o =~ /^($symbol_re|$namespace_re)$/) {
        $type = 'Lingy::KeySymbol';
    }

    $type or return WWW $o, "Don't know how to print internal value '$o'";

    $type eq ATOM ? "(atom ${\ $self->pr_str($o->[0], $raw)})" :
    $type eq STRING ? $raw ? $$o :
        qq{"${local $_ = $$o; s/([\n\t\"\\])/$escape->{$1}/ge; \$_}"} :
    $type eq REGEX ? $raw ? $$o :
        qq{#"${local $_ = $$o; \ substr($_, 4, length($_) - 5)}"} :
    $type eq 'Lingy::KeySymbol' ? $o :
    $type eq SYMBOL ? $$o :
    $type eq KEYWORD ? $$o :
    $type eq NUMBER ? $$o :
    $type eq BOOLEAN ? $$o ? 'true' : 'false' :
    $type eq NIL ? 'nil' :
    $type eq VAR ? ("#'" . $$o) :
    $type eq CLASS ? $o->_name :
    $type eq CHARACTER ? $o->print($raw) :
    $type eq 'CODE' ? "#<function ${\ sub_name($o)}>" :
    $type eq FUNCTION ? '#<Function>' :
    $type eq MACRO ? '#<Macro>' :
    $type eq LIST ?
        "(${\ join(' ', map $self->pr_str($_, $raw), @$o)})" :
    $type eq VECTOR ?
        "[${\ join(' ', map $self->pr_str($_, $raw), @$o)}]" :
    $type eq HASHMAP ?
        "{${\ join(', ', map {
            my ($key, $val) = ($_, $o->{$_});
            if ($key =~ /^:/) {
                $key = KEYWORD->new($key);
            } elsif ($key =~ s/^\"//) {
                $key = STRING->new($key);
            } elsif ($key =~ s/^(\S+) $/$1/) {
                $key = SYMBOL->new($key);
            }
            ($self->pr_str($key, $raw) . ' ' . $self->pr_str($val, $raw))
        } keys %$o)}}" :
    $type =~ /^(?:(?:quasi|(?:splice_)?un)?quote|deref)$/ ?
        "(${$type=~s/_/-/g;\$type} ${\ $self->pr_str($o->[0], $raw)})" :
    $type eq 'Lingy::Env' ? '#<Env>' :
    $type eq 'lingy-internal' ? "" :
    (blessed($o) and $o->isa(NAMESPACE)) ?
        qq(#<Namespace ${\ $o->_name}>) :
    Dump($o) .
        "*** Unrecognized Lingy value printed above ***\n";
}

1;

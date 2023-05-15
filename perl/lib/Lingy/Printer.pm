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
    my ($o, $raw) = (@_, 0);
    my $type = ref $o;

    # Hack to allow map key strings to print like symbols:
    if (not $type and $o =~ /$symbol_re$/) {
        $type = 'Lingy::Lang::KeySymbol';
    }

    $type or XXX $o, "Don't know how to print internal value '$o'";

    $type eq ATOM ? "(atom ${\pr_str($o->[0], $raw)})" :
    $type eq STRING ? $raw ? $$o :
        qq{"${local $_ = $$o; s/([\n\t\"\\])/$escape->{$1}/ge; \$_}"} :
    $type eq REGEX ? $raw ? $$o :
        qq{#"${local $_ = $$o; s/([\n\t\"\\])/$escape->{$1}/ge; \$_}"} :
    $type eq 'Lingy::Lang::KeySymbol' ? $o :
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
        "(${\ join(' ', map pr_str($_, $raw), @$o)})" :
    $type eq VECTOR ?
        "[${\ join(' ', map pr_str($_, $raw), @$o)}]" :
    $type eq HASHMAP ?
        "{${\ join(', ', map {
            my ($key, $val) = ($_, $o->{$_});
            if ($key =~ /^:/) {
                $key = keyword($key);
            } elsif ($key =~ s/^\"//) {
                $key = string($key);
            } elsif ($key =~ s/^(\S+) $/$1/) {
                $key = symbol($key);
            }
            (pr_str($key, $raw) . ' ' . pr_str($val, $raw))
        } keys %$o)}}" :
    $type =~ /^(?:(?:quasi|(?:splice_)?un)?quote|deref)$/ ?
        "(${$type=~s/_/-/g;\$type} ${\ pr_str($o->[0], $raw)})" :
    $type eq 'Lingy::Env' ? '#<Env>' :
    $type eq 'lingy-internal' ? "" :
    not(blessed($o)) ? do {
        WWW($o);
        err "Tried to print the unblessed internal reference above";
    } :
    $o->isa('Lingy::Namespace') ? qq(#<Namespace ${\ $o->NAME}>) :
    die "Don't know how to pr_str: '$o'";
}

1;

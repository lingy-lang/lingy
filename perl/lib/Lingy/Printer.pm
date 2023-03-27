use strict; use warnings;
package Lingy::Printer;

use Lingy::Common;

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
    my $type = ref $o or XXX $o;

    $type eq 'Lingy::Lang::Atom' ? "(atom ${\pr_str($o->[0], $raw)})" :
    $type eq 'Lingy::Lang::String' ? $raw ? $$o :
        qq{"${local $_ = $$o; s/([\n\t\"\\])/$escape->{$1}/ge; \$_}"} :
    $type eq 'Lingy::Lang::Symbol' ? $$o :
    $type eq 'Lingy::Lang::Keyword' ? $$o :
    $type eq 'Lingy::Lang::Number' ? $$o :
    $type eq 'Lingy::Lang::Boolean' ? $$o ? 'true' : 'false' :
    $type eq 'Lingy::Lang::Nil' ? 'nil' :
    $type eq 'Lingy::Lang::Var' ? ("#'" . $$o) :
    $type eq 'Lingy::Lang::Type' ? $$o :
    $type eq 'CODE' ? "#<function ${\ sub_name($o)}>" :
    $o->isa('Lingy::NS') ? qq(#<Namespace ${\ $o->{' NAME'}}>) :
    $type eq 'Lingy::Lang::Function' ? '#<Function>' :
    $type eq 'macro' ? '#<Macro>' :
    $type eq 'Lingy::Lang::List' ?
        "(${\ join(' ', map pr_str($_, $raw), @$o)})" :
    $type eq 'Lingy::Lang::Vector' ?
        "[${\ join(' ', map pr_str($_, $raw), @$o)}]" :
    $type eq 'Lingy::Lang::HashMap' ?
        "{${\ join(' ', map {
            my ($key, $val) = ($_, $o->{$_});
            if ($key =~ /^:/) {
                $key = keyword($key);
            } elsif ($key =~ s/^\"//) {
                $key = string($key);
            }
            (pr_str($key, $raw), pr_str($val, $raw))
        } keys %$o)}}" :
    $type =~ /^(?:(?:quasi|(?:splice_)?un)?quote|deref)$/ ?
        "(${$type=~s/_/-/g;\$type} ${\ pr_str($o->[0], $raw)})" :
    die "Don't know how to pr_str: '$o'";
}

1;

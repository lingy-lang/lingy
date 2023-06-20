use strict; use warnings;
package Lingy::Clojure;

use Lingy::Common;
use Lingy::RT;

sub require {
    my ($sym) = @_;
    $$sym =~ s/^clojure\./lingy.clojure./;
    local $Lingy::RT::require_ext = 'clj';
    no warnings 'redefine';
    local *Lingy::RT::rep = \&rep;
    Lingy::RT::require($sym);
}

sub rep {
    my (undef, $text) = @_;
    my ($expr) = RT->reader->read_str($text);
    my ($undef, $file) = @$expr;
    my $content = Lingy::RT::slurp("$file");
    my (@forms) = RT->reader->read_str($content);
    return;
    for my $form (@forms) {
        eval {
        print "$form->[0] $form->[1]\n";
        };
        print "$form\n" if $@;
        #eval { evaluate($form) }
    }
}

1;

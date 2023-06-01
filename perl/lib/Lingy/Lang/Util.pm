use strict; use warnings;
package Lingy::Lang::Util;

use Lingy::Common;

sub identical {
    boolean(refaddr($_[0]) == refaddr($_[1]));
}

#------------------------------------------------------------------------------
# Devel functions:
#------------------------------------------------------------------------------

sub applyTo {
    my ($method, $args) = @_;
    no strict 'refs';
    &{"$method"}(@$args);
}

sub eval_perl {
    my $ret = eval("$_[0]");
    $_[1] // $ret;
}

sub rt_internal { my $m = "$_[0]"; Lingy::Lang::RT->rt->$m }

sub env_data {
    my $env = $Lingy::Eval::ENV;
    my $www = {};
    my $w = $www;
    my $e = $env;
    while ($e) {
        $w->{'+'} = join ' ', sort CORE::keys %{$e->space};
        $w->{'^'} = {};
        $w = $w->{'^'};
        $e = $e->{outer};
    }
    bless $www, 'lingy-internal';
}

1;

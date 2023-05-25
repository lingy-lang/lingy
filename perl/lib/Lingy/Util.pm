use strict; use warnings;
package Lingy::Util;

use Lingy::Namespace;
use base 'Lingy::Namespace';
use Lingy::Common;

use constant NAME => 'lingy.util';

our %ns = (
    fn('eval-perl'   => 1 => sub { eval("$_[0]") },
                     => 2 => sub { eval("$_[0]"); $_[1] }),

    fn('x-carp-off'  => 0 => sub { eval "no Carp::Always"; nil }),
    fn('x-carp-on'   => 0 => sub { eval "use Carp::Always"; nil }),
    fn('x-core'      => 0 => sub { Lingy::RT->rt->core }),
    fn('x-env'       => 0 => sub { Lingy::RT->rt->env }),
    fn('x-ns'        => 0 => sub { Lingy::RT->rt->ns }),
    fn('x-refer'     => 0 => sub { Lingy::RT->rt->refer }),
    fn('x-user'      => 0 => sub { Lingy::RT->rt->user }),

    fn('x-pp-env' => '*' => sub {
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
    }),

    fn('PPP' => '*' => \&PPP),
    fn('WWW' => '*' => \&WWW),
    fn('XXX' => '*' => \&XXX),
    fn('YYY' => '*' => \&YYY),
    fn('ZZZ' => '*' => \&ZZZ),
);

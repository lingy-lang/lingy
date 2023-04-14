use strict; use warnings;
package Lingy::Util;

use Lingy::Namespace;
use base 'Lingy::Namespace';
use Lingy::Common;

# use constant getName => symbol('lingy.Util');
use constant NAME => 'lingy.Util';

our %ns = (
    fn('env'        => '0' => sub { $Lingy::RT::env }),
    fn('core'       => '0' => sub { $Lingy::RT::core }),
    fn('user'       => '0' => sub { $Lingy::RT::user }),

    fn('HOST'       => '1' => sub { WWW eval "$_[0]" }),

    fn('ENV'        => '*' => sub {
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
        WWW($www);      # Print the env
        nil;
    }),

    fn('PPP'        => '*' => \&PPP),
    fn('WWW'        => '*' => \&WWW),
    fn('XXX'        => '*' => \&XXX),
    fn('YYY'        => '*' => \&YYY),
    fn('ZZZ'        => '*' => \&ZZZ),
);

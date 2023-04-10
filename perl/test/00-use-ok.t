use Lingy::Test;

use File::Find;

my @modules;
File::Find::find sub {
    if ($File::Find::name =~ /\.pm$/) {
        my $module = $File::Find::name;
        $module =~ s{^lib/(.*)\.pm$}{$1};
        $module =~ s{/}{::}g;
        push @modules, $module;
    }
}, 'lib';

use_ok $_ for sort @modules;

done_testing;

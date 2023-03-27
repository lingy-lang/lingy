package Lingy::Lang::RT;

use Lingy::NS 'lingy.lang.RT';

my $nextID = int(rand 1000000);

our %ns = (
    fn('nextID'     => '0' => sub { string($nextID += 3) }),
    fn('refer'      => '*' => \&refer),
    fn('require'    => '*' => \&require),
);

sub nextID {
    string($nextID += 3);
}

sub refer {
    my (@specs) = @_;
    for my $spec (@specs) {
        err "'refer' only works with symbols"
            unless ref($spec) eq 'Lingy::Lang::Symbol';
        my $refer_ns_name = $$spec;
        my $current_ns_name = $Lingy::RT::ns;
        my $refer_ns = $Lingy::RT::ns{$refer_ns_name}
            or err "No namespace: '$refer_ns_name'";
        my $refer_map = $Lingy::RT::refer{$current_ns_name} //= {};
        map $refer_map->{$_} = $refer_ns_name,
            grep /^\S/, keys %$refer_ns;
    }
    return nil;
}

sub require {
    outer:
    for my $spec (@_) {
        err "'require' only works with symbols"
            unless ref($spec) eq 'Lingy::Lang::Symbol';

        return nil if $Lingy::RT::ns{$$spec};

        my $name = $$spec;

        my $path = $name;
        $path =~ s/^lingy\.lang\./Lingy.Lang\./;
        $path =~ s/^lingy\./Lingy\./;
        my $module = $path;
        $path =~ s/\./\//g;

        for my $inc (@INC) {
            $inc =~ s{^([^/.])}{./$1};
            if (-f "$inc/$path.pm") {
                CORE::require("$inc/$path.pm");
                $module =~ s/\./::/g;
                no strict 'refs';
                $module->new(name => $name);
                next outer;
            } elsif (-f "$inc/$path.ly") {
                my $ns = $Lingy::RT::ns{$Lingy::RT::ns};
                Lingy::RT->rep(qq< (load-file "$inc/$path.ly") >);
                $ns->current;
                next outer;
            }
        }
        err "Can't find library for (require '$name)";
    }
    return nil;
}

1;

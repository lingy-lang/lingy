use strict; use warnings;
package Lingy::Env;

use Lingy::Common;

sub space { shift->{space} }

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        outer => $args{outer},
        space => $args{space} // {},
    }, $class;
    my $binds = [ @{$args{binds} // []} ];
    my $exprs = $args{exprs} // [];
    while (@$binds) {
        if ("$binds->[0]" eq '&') {
            shift @$binds;
            $exprs = [list([@$exprs])];
        }
        $self->{space}{shift(@$binds)} = (shift(@$exprs) // nil);
    }
    if (my $outer = $self->{outer}) {
        $self->{LOOP} = $outer->{LOOP} if $outer->{LOOP};
        $self->{RECUR} = $outer->{RECUR} if $outer->{RECUR};
    }
    return $self;
}

sub set {
    my ($self, $symbol, $value) = @_;
    my $space = $self->{space};
    $space->{$symbol} = $value;
    return ref($space) eq 'HASH'
        ? $symbol
        : symbol($space->NAME . "/$symbol");
}

sub ns_set {
    my ($self, $symbol, $value) = @_;
    my $space = RT->current_ns();
    $space->{$symbol} = $value;
    return ref($space) eq 'HASH'
        ? $symbol
        : symbol($space->NAME . "/$symbol");
}

sub get {
    my ($self, $symbol, $optional) = @_;

    return $self->get_qualified($symbol, $optional)
        if $symbol =~ m{./.};

    while ($self) {
        my $ns = $self->space;
        if (defined(my $value = _referred($ns, $symbol))) {
            return $value;
        }
        $self = $self->{outer};
    }

    if (my $class = RT->current_ns->{"$symbol"}) {
        return $class;
    }

    err "Class not found: '$symbol'"
        if $symbol =~ /\w\.\w/;

    return if $optional;

    err "Unable to resolve symbol: '$symbol' in this context";
}

sub get_qualified {
    my ($self, $symbol, $optional) = @_;

    $symbol =~ m{^(.*)/(.*)$} or die;
    my $space_name = $1;
    my $symbol_name = $2;

    if (my $ns = RT->core_ns) {
        if (my $class = RT->core_ns->{$space_name}) {
            return \&{"${class}::$symbol_name"};
        }
    }
    if (my $class = RT->current_ns->{$space_name}) {
        return \&{"${class}::$symbol_name"};
    }

    my $ns = RT->namespaces->{$space_name}
        or err "No such namespace: '$space_name'";

    if (defined(my $value = _referred($ns, $symbol_name))) {
        return $value;
    }

    return if $optional;

    err "Unable to resolve symbol: '$symbol' in this context";
}

sub _referred {
    my ($ns, $symbol) = @_;
    if (defined(my $value = $ns->{$symbol})) {
        return $value;
    }
    if (ref($ns) ne 'HASH') {
        if (my $refer_ns_map = RT->ns_refers->{$ns->NAME}) {
            if (my $refer_ns_name = $refer_ns_map->{$symbol}) {
                if (my $refer_ns =
                    RT->namespaces->{$refer_ns_name}
                ) {
                    if (defined(my $value = $refer_ns->{$symbol})) {
                        return $value;
                    }
                }
            }
        }
    }
    return;
}

1;

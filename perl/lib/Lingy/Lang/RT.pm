use strict; use warnings;
package Lingy::Lang::RT;

use Lingy::Common;
use Lingy::Eval;
use Lingy::Namespace();
use Lingy::Printer;
use Lingy::Lang::Class;

our $nextID = 1000;

our %meta;

sub all_ns {
    list([
        map { $Lingy::Main::ns{$_} }
        sort keys %Lingy::Main::ns
    ]);
}

sub apply {
    my ($fn, $args) = @_;
    push @$args, @{pop(@$args)};
    ref($fn) eq 'CODE'
        ? $fn->(@$args)
        : Lingy::Eval::eval($fn->(@$args));
}

sub atom_ { atom($_[0]) }

sub atom_Q { boolean(ref($_[0]) eq ATOM) }

sub boolean_Q { boolean($_[0]->isa(BOOLEAN)) }

sub charCast {
    my ($char) = @_;
    my $type = ref($char);
    err "Class '$type' cannot be cast to 'lingy.lang.Character'"
        unless $type eq SYMBOL or $type eq NUMBER;
    return CHARACTER->read($char);
}

sub class_Q { boolean($_[0]->isa(CLASS)) }

sub concat { list([map @$_, @_]) }

sub conj {
    my ($o, @args) = @_;
    my $type = ref($o);
    $type eq LIST ? list([reverse(@args), @$o]) :
    $type eq VECTOR ? vector([@$o, @args]) :
    $type eq NIL ? nil :
    throw("conj first arg type '$type' not allowed");
}

sub cons { list([$_[0], @{$_[1]}]) }

sub contains_Q {
    my ($map, $key) = @_;
    return false unless ref($map) eq HASHMAP;
    $key =
        $key->isa(STRING) ? qq<"$key> :
        $key->isa(SYMBOL) ? qq<$key > :
        "$key";
    boolean(exists $map->{"$key"});
}

sub count {
    number(ref($_[0]) eq NIL ? 0 : scalar @{$_[0]});
}

sub create_ns {
    my ($name) = @_;
    err "Invalid ns name '$name'"
        unless $name =~ /^\w+(\.\w+)*$/;
    Lingy::Namespace->new(
        name => $name,
        refer => Lingy::Main->core,
    );
}

sub dec { $_[0] - 1 }

sub deref { $_[0]->[0] }

sub dissoc {
    my ($map, @keys) = @_;
    @keys = map {
        $_->isa(STRING) ? qq<"$_> : "$_";
    } @keys;
    $map = { %$map };
    delete $map->{$_} for @keys;
    hash_map([%$map]);
}

sub false_Q {
    boolean(
        ref($_[0]) eq BOOLEAN and not "$_[0]"
    );
}

sub find_ns {
    assert_args(\@_, SYMBOL);
    $Lingy::Main::ns{$_[0]} // nil;
}

sub first {
    ref($_[0]) eq NIL
        ? nil : @{$_[0]} ? $_[0]->[0] : nil;
}

sub fn_Q {
    boolean(ref($_[0]) eq FUNCTION or ref($_[0]) eq 'CODE');
}

sub get {
    my ($map, $key, $default) = @_;
    return nil unless ref($map) eq HASHMAP;
    $key = qq<"$key> if $key->isa(STRING);
    $map->{"$key"} // $default // nil;
}

sub getenv {
    my $val = $ENV{$_[0]};
    defined($val) ? string($val) : nil;
}

sub hash_map_ { hash_map([@_]) }

sub in_ns {
    my ($name) = @_;
    err "Invalid ns name '$name'"
        unless $name =~ /^\w+(\.\w+)*$/;
    my $ns = $Lingy::Main::ns{$name} //
    Lingy::Namespace->new(
        name => $name,
    );
    $ns->current;
}

sub inc { $_[0] + 1 }

sub keys_ {
    list([
        map {
            s/^"// ? string($_) :
            s/^:// ? keyword($_) :
            s/ $// ? symbol($_) :
            symbol("$_");
        } keys %{$_[0]}
    ]);
}

sub keyword_ { keyword($_[0]) }

sub keyword_Q { boolean(ref($_[0]) eq KEYWORD) }

sub list_ { list([@_]) }

sub list_Q { boolean(ref($_[0]) eq LIST) }

sub macro_Q { boolean(ref($_[0]) eq MACRO) }

sub macroexpand {
    Lingy::Eval::macroexpand($_[0], $Lingy::Eval::ENV);
}

sub map {
    list([
        map apply($_[0], [$_, []]), @{$_[1]}
    ]);
}

sub map_Q {
    boolean(ref($_[0]) eq HASHMAP);
}

sub meta {
    $meta{"$_[0]"} // nil;
}

sub name {
    string($_[0] =~ m{(.*?)/(.*)} ? $2 : "$_[0]");
}

sub namespace {
    $_[0] =~ m{(.*?)/(.*)} ? string($1) : nil;
}

sub nil_Q {
    boolean(ref($_[0]) eq NIL);
}

sub nextID {
    string(++$nextID);
}

sub ns {
    my ($name, $args) = @_;
    err "Invalid ns name '$name'"
        unless $name =~ /^\w+(\.\w+)*$/;

    my $ns;
    $ns = $Lingy::Main::ns{$name} //
    Lingy::Namespace->new(
        name => $name,
        refer => Lingy::Main->core,
    );
    $ns->current;

    for my $arg (@$args) {
        err "Invalid ns arg" unless
            $arg->isa(LIST) and
            @$arg >= 2 and
            ref($arg->[0]) eq KEYWORD;

        my ($keyword, @args) = @$arg;
        if ($$keyword eq ':use') {
            for my $spec (@args) {
                Lingy::Eval::eval(
                    list([
                        symbol('use'),
                        list([symbol('quote'), $spec]),
                    ]),
                    $Lingy::Eval::ENV,
                );
            }
        }
        elsif ($$keyword eq ':import') {
            my (undef, @args) = @$arg;
            Lingy::Eval::eval(
                list([ symbol('import'), @args ]),
                $Lingy::Eval::ENV,
            );
        }
        else {
            err "Invalid keyword arg '$keyword' in ns";
        }
    }

    nil;
}

sub nth { $_[0][$_[1]] }

sub number_ { number("$_[0]" + 0) }

sub number_Q { boolean(ref($_[0]) eq NUMBER) }

sub pos_Q { $_[0] > 0 ? true : false }

sub pr_str {
    string(join ' ', map Lingy::Printer::pr_str($_), @_);
}

sub println {
    printf "%s\n", join ' ',
        map Lingy::Printer::pr_str($_, 1), @_;
    nil;
}

sub prn {
    printf "%s\n", join ' ',
    map Lingy::Printer::pr_str($_), @_;
    nil;
}

sub quot { number(int($_[0] / $_[1])) }

sub read_string {
    my @forms = $Lingy::Main::reader->read_str($_[0]);
    return @forms ? $forms[0] : nil;
}

sub readline {
    require Lingy::ReadLine;
    my $l = Lingy::ReadLine::readline() // return;
    chomp $l;
    string($l);
}

sub refer {
    my (@specs) = @_;
    for my $spec (@specs) {
        err "'refer' only works with symbols"
            unless ref($spec) eq SYMBOL;
        my $refer_ns_name = $$spec;
        my $current_ns_name = $Lingy::Main::ns;
        my $refer_ns = $Lingy::Main::ns{$refer_ns_name}
            or err "No namespace: '$refer_ns_name'";
        my $refer_map = $Lingy::Main::refer{$current_ns_name} //= {};
        map $refer_map->{$_} = $refer_ns_name,
            grep /^\S/, keys %$refer_ns;
    }
    return nil;
}

sub require {
    outer:
    for my $spec (@_) {
        err "'require' only works with symbols"
            unless ref($spec) eq SYMBOL;

        return nil if $Lingy::Main::ns{$$spec};

        my $name = $$spec;

        my $path = $name;
        $path =~ s/^lingy\.lang\./Lingy.Lang\./;
        $path =~ s/^lingy\./Lingy\./;
        my $module = $path;
        $path =~ s/\./\//g;

        for my $inc (@INC) {
            $inc =~ s{^([^/.])}{./$1};
            my $inc_path = "$inc/$path";
            if (-f "$inc_path.pm" or -f "$inc_path.ly") {
                if (-f "$inc_path.pm") {
                    CORE::require("$inc_path.pm");
                    $module =~ s/\./::/g;
                    err "Can't require $name. " .
                        "$module is not a Lingy::Namespace."
                        unless $module->isa('Lingy::Namespace');
                    $module->new(
                        name => symbol($name),
                        refer => Lingy::Main->core,
                    );
                }
                if (-f "$inc_path.ly") {
                    my $ns = $Lingy::Main::ns{$Lingy::Main::ns};
                    Lingy::Main->rep(qq< (load-file "$inc_path.ly") >);
                    $ns->current;
                }
                next outer;
            }
        }
        err "Can't find library for (require '$name)";
    }
    return nil;
}

sub reset_BANG { $_[0]->[0] = $_[1] }

sub resolve {
    my ($symbol) = @_;
    my ($ns_name, $sym_name, $var);
    if ($symbol =~ /(.*?)\/(.*)/) {
        ($ns_name, $sym_name) = ($1, $2);
    }
    else {
        $ns_name = $Lingy::Main::ns;
        $sym_name = $symbol;
    }

    my $ns = $Lingy::Main::ns{$ns_name} or return nil;
    if (exists $ns->{$sym_name}) {
        $var = $ns_name . '/' . $sym_name;
    } else {
        my $ref;
        if (($ref = $Lingy::Main::refer{$ns_name}) and
            defined($ns_name = $ref->{$sym_name})
        ) {
            $var = $ns_name . '/' . $sym_name;
        } else {
            return nil;
        }
    }
    return var($var);
}

sub rest {
    my ($list) = @_;
    return list([]) if $list->isa(NIL) or not @$list;
    list([@{$list}[1..(@$list-1)]]);
}

sub seq {
    my ($o) = @_;
    $o->can('_to_seq') or
        err(sprintf "Don't know how to create ISeq from: %s", $o->NAME);
    $o->_to_seq;
}

sub seq_Q {$_[0]->isa(LISTTYPE)}

sub sequential_Q {
    boolean(ref($_[0]) eq LIST or ref($_[0]) eq VECTOR);
}

sub slurp { string(Lingy::Main->slurp($_[0])) }

sub sort {
    list([
        CORE::sort @{$_[0]}
    ]);
}

sub str {
    string(
        join '',
            map Lingy::Printer::pr_str($_, 1),
            grep {ref($_) ne NIL}
            @_
    );
}

sub string_Q { boolean(ref($_[0]) eq STRING) }

sub swap_BANG {
    my ($atom, $fn, $args) = @_;
    $atom->[0] = apply($fn, [[$atom->[0], @$args]]);
}

sub symbol_ { symbol("$_[0]") }

sub symbol_Q { boolean(ref($_[0]) eq SYMBOL) }

sub the_ns {
    $_[0]->isa('Lingy::Namespace') ? $_[0] :
    $_[0]->isa(SYMBOL) ? do {
        $Lingy::Main::ns{$_[0]} //
        err "No namespace: '$_[0]' found";
    } : err "Invalid argument for the-ns: '$_[0]'";
}

sub time_ms {
    require Time::HiRes;
    my ($s, $m) = Time::HiRes::gettimeofday();
    number($s * 1000 + $m / 1000);
}

sub true_Q {
    boolean(
        ref($_[0]) eq BOOLEAN and "$_[0]"
    );
}

sub type_ {
    class(ref($_[0]));
}

sub with_meta {
    my ($o, $m) = @_;
    $o = ref($o) eq 'CODE' ? sub { goto &$o } : $o->clone;
    $meta{$o} = $m;
    $o;
}

sub vals { list([ values %{$_[0]} ]) }

sub var_ { var($_[0]) }

sub vec { vector([@{$_[0]}]) }

sub vector_ { vector([@_]) }

sub vector_Q { boolean(ref($_[0]) eq VECTOR) }

1;

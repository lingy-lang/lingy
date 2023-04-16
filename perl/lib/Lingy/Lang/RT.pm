use strict; use warnings;
package Lingy::Lang::RT;

use Lingy::Common;
use Lingy::Eval;
use Lingy::Namespace();
use Lingy::Printer;

my $nextID = int(rand 5000) + 1000;

our %meta;

sub all_ns {
    list([
        map { $Lingy::RT::ns{$_} }
        sort keys %Lingy::RT::ns
    ]);
}

sub apply {
    my ($fn, $args) = @_;
    push @$args, @{pop(@$args)};
    ref($fn) eq 'CODE'
        ? $fn->(@$args)
        : Lingy::Eval::eval($fn->(@$args));
}

sub assoc {
    my ($map, @pairs) = @_;
    for (my $i = 0; $i < @pairs; $i += 2) {
        $pairs[$i] = qq<"$pairs[$i]>
            if $pairs[$i]->isa('Lingy::Lang::String');
    }
    hash_map([%$map, @pairs]);
}

sub atom_ { atom($_[0]) }

sub atom_Q { boolean(ref($_[0]) eq 'Lingy::Lang::Atom') }

sub boolean_Q { boolean($_[0]->isa('Lingy::Lang::Boolean')) }

sub charCast {
    my ($char) = @_;
    my $type = ref($char);
    err "Class '$type' cannot be cast to 'lingy.lang.Character'"
        unless $type =~ /^Lingy::Lang::(?:Symbol|Number)$/;
    return Lingy::Lang::Character->read($char);
}

sub concat { list([map @$_, @_]) }

sub conj {
    my ($o, @args) = @_;
    my $type = ref($o);
    $type eq 'Lingy::Lang::List' ? list([reverse(@args), @$o]) :
    $type eq 'Lingy::Lang::Vector' ? vector([@$o, @args]) :
    $type eq 'Lingy::Lang::Nil' ? nil :
    throw("conj first arg type '$type' not allowed");
}

sub cons { list([$_[0], @{$_[1]}]) }

sub contains_Q {
    my ($map, $key) = @_;
    return false unless ref($map) eq 'Lingy::Lang::HashMap';
    $key = qq<"$key> if $key->isa('Lingy::Lang::String');
    boolean(exists $map->{"$key"});
}

sub count {
    number(ref($_[0]) eq 'Lingy::Lang::Nil' ? 0 : scalar @{$_[0]});
}

sub create_ns {
    my ($name) = @_;
    err "Invalid ns name '$name'"
        unless $name =~ /^\w+(\.\w+)*$/;
    Lingy::Namespace->new(
        name => $name,
        refer => $Lingy::RT::core->NAME,
    );
}

sub dec { $_[0] - 1 }

sub deref { $_[0]->[0] }

sub dissoc {
    my ($map, @keys) = @_;
    @keys = map {
        $_->isa('Lingy::Lang::String') ? qq<"$_> : "$_";
    } @keys;
    $map = { %$map };
    delete $map->{$_} for @keys;
    hash_map([%$map]);
}

sub empty_Q { boolean(@{$_[0]} == 0) }

sub false_Q {
    boolean(
        ref($_[0]) eq 'Lingy::Lang::Boolean' and not "$_[0]"
    );
}

sub find_ns {
    $Lingy::RT::ns{$_[0]} // nil;
}

sub first {
    ref($_[0]) eq 'Lingy::Lang::Nil'
        ? nil : @{$_[0]} ? $_[0]->[0] : nil;
}

sub fn_Q {
    boolean(ref($_[0]) =~ /^(Lingy::Lang::Function|CODE)$/);
}

sub get {
    my ($map, $key, $default) = @_;
    return nil unless ref($map) eq 'Lingy::Lang::HashMap';
    $key = qq<"$key> if $key->isa('Lingy::Lang::String');
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
    my $ns = $Lingy::RT::ns{$name} //
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
            symbol("$_");
        } keys %{$_[0]}
    ]);
}

sub keyword_ { keyword($_[0]) }

sub keyword_Q { boolean(ref($_[0]) eq 'Lingy::Lang::Keyword') }

sub list_ { list([@_]) }

sub list_Q { boolean(ref($_[0]) eq 'Lingy::Lang::List') }

sub macro_Q { boolean(ref($_[0]) eq 'Lingy::Lang::Macro') }

sub macroexpand {
    Lingy::Eval::macroexpand($_[0], $Lingy::Eval::ENV);
}

sub map {
    list([
        map apply($_[0], [$_, []]), @{$_[1]}
    ]);
}

sub map_Q {
    boolean(ref($_[0]) eq "Lingy::Lang::HashMap");
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
    boolean(ref($_[0]) eq 'Lingy::Lang::Nil');
}

sub nextID {
    string($nextID += 3);
}

sub ns {
    my ($name) = @_;
    err "Invalid ns name '$name'"
        unless $name =~ /^\w+(\.\w+)*$/;
    Lingy::Namespace->new(
        name => $name,
        refer => $Lingy::RT::core->NAME,
    )->current;
    nil;
}

sub nth { $_[0][$_[1]] }

sub number_ { number("$_[0]" + 0) }

sub number_Q { boolean(ref($_[0]) eq 'Lingy::Lang::Number') }

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
    my @forms = $Lingy::RT::reader->read_str($_[0]);
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

sub reset_BANG { $_[0]->[0] = $_[1] }

sub resolve {
    my ($symbol) = @_;
    my ($ns_name, $sym_name, $var);
    if ($symbol =~ /(.*?)\/(.*)/) {
        ($ns_name, $sym_name) = ($1, $2);
    }
    else {
        $ns_name = $Lingy::RT::ns;
        $sym_name = $symbol;
    }

    my $ns = $Lingy::RT::ns{$ns_name} or return nil;
    if (exists $ns->{$sym_name}) {
        $var = $ns_name . '/' . $sym_name;
    } else {
        my $ref;
        if (($ref = $Lingy::RT::refer{$ns_name}) and
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
    return list([]) if $list->isa('Lingy::Lang::Nil') or not @$list;
    list([@{$list}[1..(@$list-1)]]);
}

sub seq {
    my ($o) = @_;
    my $type = ref($o);
    $type eq 'Lingy::Lang::List' ? @$o ? $o : nil :
    $type eq 'Lingy::Lang::Vector' ? @$o ? list([@$o]) : nil :
    $type eq 'Lingy::Lang::String' ? length($$o)
        ? list([map string($_), split //, $$o]) : nil :
    $type eq 'Lingy::Lang::Nil' ? nil :
    throw("seq does not support type '$type'");
}

sub seq_Q {$_[0]->isa('Lingy::Lang::ListClass')}

sub sequential_Q {
    boolean(ref($_[0]) =~ /^(Lingy::Lang::List|Lingy::Lang::Vector)/);
}

sub slurp { string(Lingy::RT::slurp($_[0])) }

sub str {
    string(
        join '',
            map Lingy::Printer::pr_str($_, 1),
            grep {ref($_) ne 'Lingy::Lang::Nil'}
            @_
    );
}

sub string_Q { boolean(ref($_[0]) eq "Lingy::Lang::String") }

sub swap_BANG {
    my ($atom, $fn, $args) = @_;
    $atom->[0] = apply($fn, [[$atom->[0], @$args]]);
}

sub symbol_ { symbol("$_[0]") }

sub symbol_Q { boolean(ref($_[0]) eq 'Lingy::Lang::Symbol') }

sub the_ns {
    $_[0]->isa('Lingy::Namespace') ? $_[0] :
    $_[0]->isa('Lingy::Lang::Symbol') ? do {
        $Lingy::RT::ns{$_[0]} //
        err "No namespace: '$_[0]' found";
    } : err "Invalid argument for the-ns: '$_[0]'";
}

sub throw { die $_[0] }

sub time_ms {
    require Time::HiRes;
    my ($s, $m) = Time::HiRes::gettimeofday();
    number($s * 1000 + $m / 1000);
}

sub true_Q {
    boolean(
        ref($_[0]) eq 'Lingy::Lang::Boolean' and "$_[0]"
    );
}

sub type_ {
    class(
        $_[0]->can('NAME')
            ? $_[0]->NAME
            : ref($_[0])
    );
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

sub vector_Q { boolean(ref($_[0]) eq "Lingy::Lang::Vector") }

1;

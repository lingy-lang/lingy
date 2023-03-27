package Lingy::Core;

use Lingy::NS 'lingy.core';

use Lingy::Env;
use Lingy::Eval;
use Lingy::Printer;

our %meta;

# Initialize the lingy.core namespace by setting some dynamic vars and loading
# Lingy/core.ly.
#
sub init {
    my $self = shift;

    my $env = $Lingy::RT::env;
    $env->set('*file*', string($ARGV[0]));
    $env->set('*ARGV*', list([map string($_), @ARGV[1..$#ARGV]]));
    $env->set(
        '*command-line-args*',
        list([map string($_), @ARGV[1..$#ARGV]])
    );
    $env->set(eval => sub { Lingy::Eval::eval($_[0], $env) });

    $self->load;

    Lingy::RT->rep(qq((def *host* \"${\ Lingy::RT->host}\")));

    return $self;
}

# These sub need to be able to be called directly:
sub apply {
    my ($fn, @args) = @_;
    push @args, @{pop(@args)};
    ref($fn) eq 'CODE'
        ? $fn->(@args)
        : Lingy::Eval::eval($fn->(@args));
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

sub str {
    string(join '', map Lingy::Printer::pr_str($_, 1), @_);
}

our %ns = (

fn('all-ns' =>
    '0' => sub {
        list([
            map { $Lingy::RT::ns{$_} }
            sort keys %Lingy::RT::ns
        ]);
    },
),

fn('apply' =>
    '*' => \&apply),

fn('assoc' =>
    '*' => sub {
        my ($map, @pairs) = @_;
        for (my $i = 0; $i < @pairs; $i += 2) {
            $pairs[$i] = qq<"$pairs[$i]>
                if $pairs[$i]->isa('Lingy::Lang::String');
        }
        hash_map([%$map, @pairs]);
    },
),

fn('atom' =>
    '*' => sub { atom(@_) }),

fn('atom?' =>
    '1' => sub { boolean(ref($_[0]) eq 'Lingy::Lang::Atom') }),

fn('boolean?' =>
    '1' => sub { boolean($_[0]->isa('Lingy::Lang::Boolean')) }),

fn('concat' =>
    '*' => sub { list([map @$_, @_]) }),

fn('conj' =>
    '*' => sub {
        my ($o, @args) = @_;
        my $type = ref($o);
        $type eq 'Lingy::Lang::List' ? list([reverse(@args), @$o]) :
        $type eq 'Lingy::Lang::Vector' ? vector([@$o, @args]) :
        $type eq 'Lingy::Lang::Nil' ? nil :
        throw("conj first arg type '$type' not allowed");
    },
),

fn('cons' =>
    '2' => sub { list([$_[0], @{$_[1]}]) }),

fn('contains?' =>
    '2' => sub {
        my ($map, $key) = @_;
        return false unless ref($map) eq 'Lingy::Lang::HashMap';
        $key = qq<"$key> if $key->isa('Lingy::Lang::String');
        boolean(exists $map->{"$key"});
    },
),

fn('count' =>
    '1' => sub {
        number(ref($_[0]) eq 'Lingy::Lang::Nil' ? 0 : scalar @{$_[0]})
    },
),

fn('create-ns' =>
    '1' => sub {
        my ($name) = @_;
        err "Invalid ns name '$name'"
            unless $name =~ /^\w+(\.\w+)*$/;
        Lingy::NS->new(
            name => $name,
            refer => $Lingy::RT::core->name,
        );
    },
),

fn('dec' =>
    '1' => sub { $_[0] - 1 }),

fn('deref' =>
    '1' => sub { $_[0]->[0] }),

fn('dissoc' =>
    '*' => sub {
        my ($map, @keys) = @_;
        @keys = map {
            $_->isa('Lingy::Lang::String') ? qq<"$_> : "$_";
        } @keys;
        $map = { %$map };
        delete $map->{$_} for @keys;
        hash_map([%$map]);
    },
),

fn('empty?' =>
    '1' => sub { boolean(@{$_[0]} == 0) }),

fn('false?' =>
    '1' => sub {
        boolean(ref($_[0]) eq 'Lingy::Lang::Boolean' and not "$_[0]"),
    },
),

fn('find-ns' =>
    '1' => sub {
        $Lingy::RT::ns{$_[0]} // nil
    },
),

fn('first' =>
    '1' => sub {
        ref($_[0]) eq 'Lingy::Lang::Nil' ? nil : @{$_[0]} ? $_[0]->[0] : nil;
    },
),

fn('fn?' =>
    '1' => sub {
        boolean(ref($_[0]) =~ /^(Lingy::Lang::Function|CODE)$/);
    },
),

fn('get' =>
    '2' => sub {
        my ($map, $key) = @_;
        return nil unless ref($map) eq 'Lingy::Lang::HashMap';
        $key = qq<"$key> if $key->isa('Lingy::Lang::String');
        $map->{"$key"} // nil;
    },
),

fn('getenv' =>
    '1' => sub {
        my $val = $ENV{$_[0]};
        defined($val) ? string($val) : nil;
    },
),

fn('hash-map' =>
    '*' => sub { hash_map([@_]) }),

fn('inc' =>
    '1' => sub { $_[0] + 1 }),

fn('in-ns' =>
    '1' => sub {
        my ($name) = @_;
        err "Invalid ns name '$name'"
            unless $name =~ /^\w+(\.\w+)*$/;
        Lingy::NS->new(
            name => $name,
        )->current;
        nil;
    },
),

fn('join' =>
    '2' => sub {
        string(join ${str($_[0])}, map ${str($_)}, @{$_[1]});
    },
),

fn('keys' =>
    '1' => sub {
        list([
            map {
                s/^"// ? string($_) :
                s/^:// ? keyword($_) :
                symbol("$_");
            } keys %{$_[0]}
        ]);
    },
),

fn('keyword' =>
    '1' => sub { keyword($_[0]) }),

fn('keyword?' =>
    '1' => sub { boolean(ref($_[0]) eq 'Lingy::Lang::Keyword') }),

fn('list' =>
    '*' => sub { list([@_]) }),

fn('list?' =>
    '1' => sub { boolean(ref($_[0]) eq 'Lingy::Lang::List') }),

fn('macro?' =>
    '1' => sub { boolean(ref($_[0]) eq 'macro') }),

fn('macroexpand' => '1' => sub {
        Lingy::Eval::macroexpand($_[0], $Lingy::Eval::ENV);
    },
),

fn('map' =>
    '2' => sub {
        list([ map apply($_[0], $_, []), @{$_[1]} ]);
    },
),

fn('map?' =>
    '1' => sub { boolean(ref($_[0]) eq "Lingy::Lang::HashMap") }),

fn('meta' =>
    '1' => sub { $meta{"$_[0]"} // nil}),

fn('name' =>
    '1' => sub {
        string($_[0] =~ m{(.*?)/(.*)} ? $2 : "$_[0]");
    },
),

fn('namespace' =>
    '1' => sub {
        $_[0] =~ m{(.*?)/(.*)} ? string($1) : nil;
    },
),

fn('next' =>
    '1' => sub { seq(rest($_[0])) }),

fn('nil?' =>
    '1' => sub { boolean(ref($_[0]) eq 'Lingy::Lang::Nil') }),

fn('-ns' =>
    '1' => sub {
        my ($name) = @_;
        err "Invalid ns name '$name'"
            unless $name =~ /^\w+(\.\w+)*$/;
        Lingy::NS->new(
            name => $name,
            refer => $Lingy::RT::core->name,
        )->current;
        nil;
    },
),

fn('ns-name' =>
    '1' => sub { string($_[0]->{' NAME'}) }),

fn('nth' =>
    '2' => sub {
        my ($list, $index) = @_;
        ($index >= 0 and $index < @$list)
            ? $list->[$index]
            : err "Index '$index' out of range";
    },
    '3' => sub {
        my ($list, $index, $default) = @_;
        ($index >= 0 and $index < @$list)
            ? $list->[$index]
            : $default;
    },
),

fn('number' =>
    '1' => sub { number("$_[0]" + 0) }),

fn('number?' =>
    '1' => sub { boolean(ref($_[0]) eq 'Lingy::Lang::Number') }),

fn('pos?', =>
    '1' => sub { $_[0] > 0 ? true : false }),

fn('pr-str' =>
    '*' => sub {
        string(join ' ', map Lingy::Printer::pr_str($_), @_);
    },
),

fn('println' =>
    '*' => sub {
        printf "%s\n", join ' ',
            map Lingy::Printer::pr_str($_, 1), @_;
        nil;
    },
),

fn('prn' =>
    '*' => sub {
        printf "%s\n", join ' ',
        map Lingy::Printer::pr_str($_), @_;
        nil;
    },
),

fn('quot' =>
    '2' => sub { number(int($_[0] / $_[1])) }),

fn('range' =>
    '2' => sub {
        my ($x, $y) = @_;
        if (not defined $y) {
            $y = $x;
            $x = number(0);
        }
        if ($y < $x) {
            list([map number($_), reverse(($y+1)..$x)]);
        } else {
            list([map number($_), $x..($y-1)]);
        }
    },
),

fn('read-string' => '1' => sub {
        my @forms = $Lingy::RT::reader->read_str($_[0]);
        return @forms ? $forms[0] : nil;
    },
),

fn('readline' =>
    '0' => sub {
        require Lingy::ReadLine;
        my $l = Lingy::ReadLine::readline() // return;
        chomp $l;
        string($l);
    },
),

fn('reduce' =>
    '2' => sub {
        my ($fn, $coll) = @_;
        (@$coll == 0) ? apply($fn, []) :
        (@$coll == 1) ? $coll->[0] :
        apply(\&reduce_3, [$fn, shift(@$coll), $coll]);
    },
    '3' => sub {
        my ($fn, $val, $coll) = @_;
        for my $e (@$coll) {
            $val = apply($fn, [$val, $e]);
        }
        $val;
    },
),

fn('reset!' =>
    '2' => sub { $_[0]->[0] = $_[1] }),

fn('resolve' =>
    '1' => sub {
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
    },
),

fn('rest' =>
    '1' => \&rest),

fn('seq' =>
    '1' => \&seq),

fn('seq?' =>
    '1' => sub {$_[0]->isa('Lingy::Base::List')}),

fn('sequential?' => '1' => sub {
        boolean(ref($_[0]) =~ /^(Lingy::Lang::List|Lingy::Lang::Vector)/);
    },
),

fn('slurp' =>
    '1' => sub { string(slurp($_[0])) }),

fn('str' =>
    '*' => \&str),

fn('string?' =>
    '1' => sub { boolean(ref($_[0]) eq "Lingy::Lang::String") }),

fn('swap!' =>
    '*' => sub {
        my ($atom, $fn, @args) = @_;
        $atom->[0] = apply($fn, [$atom->[0], @args]);
    },
),

fn('symbol' =>
    '1' => sub { symbol("$_[0]") }),

fn('symbol?' =>
    '1' => sub { boolean(ref($_[0]) eq 'Lingy::Lang::Symbol') }),

fn('the-ns' =>
    '1' => sub {
        $_[0]->isa('Lingy::NS') ? $_[0] :
        $_[0]->isa('Lingy::Lang::Symbol') ? do {
            $Lingy::RT::ns{$_[0]} //
            err "No namespace: '$_[0]' found";
        } : err "Invalid argument for the-ns: '$_[0]'";
    },
),

fn('throw' =>
    '1' => sub { die $_[0] }),

fn('time-ms' =>
    '0' => sub {
        require Time::HiRes;
        my ($s, $m) = Time::HiRes::gettimeofday();
        number($s * 1000 + $m / 1000);
    },
),

fn('true?' =>
    '1' => sub {
        boolean(ref($_[0]) eq 'Lingy::Lang::Boolean' and "$_[0]");
    },
),

fn('type' =>
    '1' => sub {
        type(
            $_[0]->can('lingy_class')
                ? $_[0]->lingy_class
                : ref($_[0])
        );
    },
),

fn('vals' =>
    '1' => sub { list([ values %{$_[0]} ]) }),

fn('var' =>
        '1' => sub { var($_[0]) }),

fn('vec' =>
    '1' => sub { vector([@{$_[0]}]) }),

fn('vector' =>
    '*' => sub { vector([@_]) }),

fn('vector?' =>
    '1' => sub { boolean(ref($_[0]) eq "Lingy::Lang::Vector") }),

fn('with-meta' =>
    '2' => sub {
        my ($o, $m) = @_;
        $o = ref($o) eq 'CODE' ? sub { goto &$o } : $o->clone;
        $meta{$o} = $m;
        $o;
    },
),

);

1;

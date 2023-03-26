use strict; use warnings;
package Lingy::Core;

use base 'Lingy::NS';

use Lingy::Types;
use Lingy::Eval;
use Lingy::Printer;

use Exporter 'import';

our @EXPORT = qw< slurp str >;

our %meta;

sub new {
    my $class = shift;

    my $self = bless {
        'add'       => fn('2' => \&add),
        'subtract'  => fn('2' => \&subtract),
        'multiply'  => fn('2' => \&multiply),
        'divide'    => fn('2' => \&divide),
        '<'         => fn('2' => \&less_than),
        '<='        => fn('2' => \&less_equal),
        '='         => fn('2' => \&equal_to),
        '=='        => fn('2' => \&equal_to),
        '>'         => fn('2' => \&greater_than),
        '>='        => fn('2' => \&greater_equal),

        'apply'     => fn('*' => \&apply),
        'assoc'     => fn('*' => \&assoc),
        'atom'      => fn('*' => \&atom_),
        'atom?'     => fn('1' => \&atom_q),
        'concat'    => fn('*' => \&concat),
        'conj'      => fn('*' => \&conj),
        'cons'      => fn('2' => \&cons),
        'contains?' => fn('2' => \&contains_q),
        'count'     => fn('1' => \&count),
        'dec'       => fn('1' => \&dec),
        'deref'     => fn('1' => \&deref),
        'dissoc'    => fn('*' => \&dissoc),
        'empty?'    => fn('1' => \&empty_q),
        'false?'    => fn('1' => \&false_q),
        'first'     => fn('1' => \&first),
        'fn?'       => fn('1' => \&fn_q),
        'get'       => fn('2' => \&get),
        'getenv'    => fn('1' => \&getenv),
        'hash-map'  => fn('*' => \&hash_map_),
        'join'      => fn('2' => \&join_),
        'keys'      => fn('1' => \&keys),
        'keyword'   => fn('1' => \&keyword_),
        'keyword?'  => fn('1' => \&keyword_q),
        'list'      => fn('*' => \&list_),
        'list?'     => fn('1' => \&list_q),
        'macro?'    => fn('1' => \&macro_q),
        'map'       => fn('2' => \&map_),
        'map?'      => fn('1' => \&map_q),
        'meta'      => fn('1' => \&meta),
        'nil?'      => fn('1' => \&nil_q),
        'nth'       => fn('2' => \&nth),
        'number'    => fn('1' => \&number_),
        'number?'   => fn('1' => \&number_q),
        'pr-str'    => fn('*' => \&pr_str),
        'println'   => fn('*' => \&println),
        'prn'       => fn('*' => \&prn),
        'range'     => fn('2' => \&range),
        'read-string' => fn('1' => \&read_string),
        'readline'  => fn('0' => \&readline_),
        'reduce'    => fn('2' => \&reduce_2,
                          '3' => \&reduce_3),
        'reset!'    => fn('2' => \&reset),
        'rest'      => fn('1' => \&rest),
        'seq'       => fn('1' => \&seq),
        'sequential?' => fn('1' => \&sequential_q),
        'slurp'     => fn('1' => \&slurp),
        'str'       => fn('*' => \&str),
        'string?'   => fn('1' => \&string_q),
        'swap!'     => fn('*' => \&swap),
        'symbol'    => fn('1' => \&symbol_),
        'symbol?'   => fn('1' => \&symbol_q),
        'throw'     => fn('1' => \&throw),
        'time-ms'   => fn('0' => \&time_ms),
        'true?'     => fn('1' => \&true_q),
        'vals'      => fn('1' => \&vals),
        'vec'       => fn('1' => \&vec),
        'vector'    => fn('*' => \&vector_),
        'vector?'   => fn('1' => \&vector_q),
        'with-meta' => fn('2' => \&with_meta),

        'ENV'       => fn('*' => \&ENV),
        'PPP'       => fn('*' => \&PPP),
        'WWW'       => fn('*' => \&WWW),
        'XXX'       => fn('*' => \&XXX),
        'YYY'       => fn('*' => \&YYY),
        'ZZZ'       => fn('*' => \&ZZZ),
    }, $class;
}

sub init {
    my $self = shift;

    my $env = RT->env;
    $env->set('*file*', string($ARGV[0]));
    $env->set('*ARGV*', list([map string($_), @ARGV[1..$#ARGV]]));
    $env->set('*command-line-args*', list([map string($_), @ARGV[1..$#ARGV]]));
    $env->set(eval => sub { Lingy::Eval::eval($_[0], $env) });

    RT->rep(<<'...'
      (defmacro! defmacro
        (fn* [name args body]
          `(defmacro! ~name (fn* ~args ~body))))

      (defmacro def [& xs] (cons 'def! xs))

      (defmacro fn [& xs] (cons 'fn* xs))

      (defmacro defn [name & body]
        `(def ~name (fn ~@body)))

      (defmacro let [& xs] (cons 'let* xs))
      (defmacro try [& xs] (cons 'try* xs))

      (defn +
        ([] 0)
        ([a] a)
        ([a b] (add a b))
        ([a b & more]
          (reduce + (+ a b) more)))

      (defn -
        ([] 0)
        ([a] (subtract 0 a))
        ([a b] (subtract a b))
        ([a b & more]
          (reduce - (- a b) more)))

      (defn *
        ([a] a)
        ([a b] (multiply a b))
        ([a b & more]
          (reduce * (* a b) more)))

      (defn /
        ([a] (divide 1 a))
        ([a b] (divide a b))
        ([a b & more]
          (reduce / (/ a b) more)))

      (defmacro cond [& xs]
        (if (> (count xs) 0)
          (list 'if (first xs)
            (if (> (count xs) 1)
              (nth xs 1)
              (throw "odd number of forms to cond"))
            (cons 'cond (rest (rest xs))))))

      (defn load-file [f]
        (eval
          (read-string
            (str
              "(do "
              (slurp f)
              "\nnil)"))))

      (defn not [a]
        (if a
          false
          true))
...
    );

    RT->rep(qq((def *host* \"$Lingy::Runtime::host\")));
}

sub add { $_[0] + $_[1] }

sub apply {
    my ($fn, @args) = @_;
    push @args, @{pop(@args)};
    ref($fn) eq 'CODE'
        ? $fn->(@args)
        : Lingy::Eval::eval($fn->(@args));
}

sub assoc {
    my ($map, @pairs) = @_;
    for (my $i = 0; $i < @pairs; $i += 2) {
        $pairs[$i] = qq<"$pairs[$i]>
            if $pairs[$i]->isa('string');
    }
    hash_map([%$map, @pairs]);
}

sub atom_ { atom(@_) }

sub atom_q { boolean(ref($_[0]) eq 'atom') }

sub concat { list([map @$_, @_]) }

sub conj {
    my ($o, @args) = @_;
    my $type = ref($o);
    $type eq 'list' ? list([reverse(@args), @$o]) :
    $type eq 'vector' ? vector([@$o, @args]) :
    $type eq 'nil' ? nil :
    throw("conj first arg type '$type' not allowed");
}

sub cons { list([$_[0], @{$_[1]}]) }

sub contains_q {
    my ($map, $key) = @_;
    return false unless ref($map) eq 'hash_map';
    $key = qq<"$key> if $key->isa('string');
    boolean(exists $map->{"$key"});
}

sub count { number(ref($_[0]) eq 'nil' ? 0 : scalar @{$_[0]}) }

sub dec { number($_[0] - 1) }

sub deref { $_[0]->[0] }

sub dissoc {
    my ($map, @keys) = @_;
    @keys = map {
        $_->isa('string') ? qq<"$_> : "$_";
    } @keys;
    $map = { %$map };
    delete $map->{$_} for @keys;
    hash_map([%$map]);
}

sub divide { $_[0] / $_[1] }

sub empty_q { boolean(@{$_[0]} == 0) }

sub equal_to {
    my ($x, $y) = @_;
    return false
        unless
            ($x->isa('Lingy::List') and $y->isa('Lingy::List')) or
            (ref($x) eq ref($y));
    if ($x->isa('Lingy::List')) {
        return false unless @$x == @$y;
        for (my $i = 0; $i < @$x; $i++) {
            my $bool = equal_to($x->[$i], $y->[$i]);
            return false if "$bool" eq '0';
        }
        return true;
    }
    if ($x->isa('hash_map')) {
        my @xkeys = sort map "$_", keys %$x;
        my @ykeys = sort map "$_", keys %$y;
        return false unless @xkeys == @ykeys;
        my @xvals = map $x->{$_}, @xkeys;
        my @yvals = map $y->{$_}, @ykeys;
        for (my $i = 0; $i < @xkeys; $i++) {
            return false unless "$xkeys[$i]" eq "$ykeys[$i]";
            my $bool = equal_to($xvals[$i], $yvals[$i]);
            return false if "$bool" eq '0';
        }
        return true;
    }
    boolean($$x eq $$y);
}

sub false_q { boolean(ref($_[0]) eq 'boolean' and not "$_[0]") }

sub first { ref($_[0]) eq 'nil' ? nil : @{$_[0]} ? $_[0]->[0] : nil }

sub fn_q { boolean(ref($_[0]) =~ /^(function|CODE)$/) }

sub get {
    my ($map, $key) = @_;
    return nil unless ref($map) eq 'hash_map';
    $key = qq<"$key> if $key->isa('string');
    $map->{"$key"} // nil;
}

sub getenv {
    my $val = $ENV{$_[0]};
    defined($val) ? string($val) : nil;
}

sub greater_equal { $_[0] >= $_[1] }

sub greater_than { $_[0] > $_[1] }

sub hash_map_ { hash_map([@_]) }

sub join_ { string(join ${str($_[0])}, map ${str($_)}, @{$_[1]}) }

sub keys {
    list([
        map {
            s/^"// ? string($_) :
            s/^:// ? keyword($_) :
            symbol("$_");
        } keys %{$_[0]}
    ]);
}

sub keyword_ { keyword($_[0]) }

sub keyword_q { boolean(ref($_[0]) eq 'keyword') }

sub less_equal { $_[0] <= $_[1] }

sub less_than { $_[0] < $_[1] }

sub list_ { list([@_]) }

sub list_q { boolean(ref($_[0]) eq 'list') }

sub macro_q { boolean(ref($_[0]) eq 'macro') }

sub map_ { list([ map apply($_[0], $_, []), @{$_[1]} ]) }

sub map_q { boolean(ref($_[0]) eq "hash_map") }

sub meta { $meta{"$_[0]"} // nil}

sub multiply { $_[0] * $_[1] }

sub nil_q { boolean(ref($_[0]) eq 'nil') }

sub nth {
    my ($list, $index) = @_;
    die "Index '$index' out of range" if $index >= @$list;
    $list->[$index];
}

sub number_ { number("$_[0]" + 0) }

sub number_q { boolean(ref($_[0]) eq "number") }

sub pr_str { string(join ' ', map Lingy::Printer::pr_str($_), @_) }

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

sub range {
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
}

sub read_string {
    my @forms = Lingy::Runtime->reader->read_str($_[0]);
    return @forms ? $forms[0] : nil;
}

sub readline_ {
    require Lingy::ReadLine;
    my $l = Lingy::ReadLine::readline() // return;
    chomp $l;
    string($l);
}

sub reduce_2 {
    my ($fn, $coll) = @_;
    (@$coll == 0) ? apply($fn, []) :
    (@$coll == 1) ? $coll->[0] :
    apply(\&reduce_3, [$fn, shift(@$coll), $coll]);
}

sub reduce_3 {
    my ($fn, $val, $coll) = @_;
    for my $e (@$coll) {
        $val = apply($fn, [$val, $e]);
    }
    $val;
}

sub reset { $_[0]->[0] = $_[1] }

sub rest {
    my ($list) = @_;
    return list([]) if $list->isa('nil') or not @$list;
    list([@{$list}[1..(@$list-1)]]);
}

sub seq {
    my ($o) = @_;
    my $type = ref($o);
    $type eq 'list' ? @$o ? $o : nil :
    $type eq 'vector' ? @$o ? list([@$o]) : nil :
    $type eq 'string' ? length($$o)
        ? list([map string($_), split //, $$o]) : nil :
    $type eq 'nil' ? nil :
    throw("seq does not support type '$type'");
}

sub sequential_q { boolean(ref($_[0]) =~ /^(list|vector)/) }

sub slurp {
    my ($file) = @_;
    open my $slurp, '<', "$file" or
        die "Couldn't open '$file' for input";
    local $/;
    string(<$slurp>);
}

sub str { string(join '', map Lingy::Printer::pr_str($_, 1), @_) }

sub string_q { boolean(ref($_[0]) eq "string") }

sub subtract { $_[0] - $_[1] }

sub symbol_ { symbol($_[0]) }

sub symbol_q { boolean(ref($_[0]) eq 'symbol') }

sub swap {
    my ($atom, $fn, @args) = @_;
    $atom->[0] = apply($fn, [deref($atom), @args]);
}

sub throw { die $_[0] }

sub time_ms {
    require Time::HiRes;
    my ($s, $m) = Time::HiRes::gettimeofday();
    number($s * 1000 + $m / 1000);
}

sub true_q { boolean(ref($_[0]) eq 'boolean' and "$_[0]") }

sub vals { list([ values %{$_[0]} ]) }

sub vec { vector([@{$_[0]}]) }

sub vector_ { vector([@_]) }

sub vector_q { boolean(ref($_[0]) eq "vector") }

sub with_meta {
    my ($o, $m) = @_;
    $o = ref($o) eq 'CODE' ? sub { goto &$o } : $o->clone;
    $meta{$o} = $m;
    $o;
}

sub ENV {
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
}

1;

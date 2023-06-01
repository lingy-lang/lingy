use strict; use warnings;
package Lingy::Lang::RT;

use Lingy;
use Lingy::Common;
use Lingy::Eval;
use Lingy::Lang::Class;
use Lingy::Lang::HashMap;
use Lingy::Lang::Nil;
use Lingy::Lang::Sequential;
use Lingy::Lang::Symbol;
use Lingy::Namespace();
use Lingy::Printer;
use Lingy::ReadLine;

use constant LANG => 'Lingy';
use constant HOST => 'perl';

use constant env_class => 'Lingy::Env';
use constant printer_class => 'Lingy::Printer';
use constant reader_class => 'Lingy::Reader';

our @class = (
    ATOM,
    BOOLEAN,
    CHARACTER,
    CLASS,
    COMPILER,
    FUNCTION,
    HASHMAP,
    KEYWORD,
    LIST,
    LISTTYPE,
    MACRO,
    NIL,
    NUMBER,
    REGEX,
    SEQUENTIAL,
    STRING,
    SYMBOL,
    VAR,
    VECTOR,
    NUMBERS,
    RT,
    TERM,
    THREAD,
    UTIL,
);

our %meta;

our $ns = '';               # Current namespace name
our %ns = ();               # Map of all namespaces
our %refer = ();            # Map of all namespace refers
bless \%ns, 'lingy-internal';
bless \%refer, 'lingy-internal';

# Preload classes:
our %class = map {
    my $class = CLASS->_new($_);
    ($class->_name, $class);
} @class;

our ($env, $reader, $printer);
our ($rt, $core, $user);

my $pr_str;

sub rt { $rt }
sub ns { \%ns }
sub NS { $ns{$ns} }
sub refer { \%refer }
sub env { $env }
sub core { $core }
sub user { $user }
sub classes { \@class }


sub new {
    my ($class) = @_;
    $rt = bless {}, $class;
}

sub init {
    my ($self) = @_;

    for my $class (keys %class) {
        my $package = $class{$class};
        eval "require $package";
        die $@ if $@;
        if ($class =~ /\.(\w+)$/) {
            $class{$1} = $package;
        }
    }

    $env     = $self->require_new($self->env_class);
    $reader  = $self->require_new($self->reader_class);
    $printer = $self->require_new($self->printer_class);

    $pr_str = $printer->can('pr_str') or die;

    $core = $self->core_namespace();
    $user = $self->user_namespace();

    $user->current;

    $Lingy::Lang::RT::ready = 1;

    return $self;
}

sub core_namespace {
    my ($self) = @_;

    my $ns = Lingy::Namespace->new(
        name => 'lingy.core',
    )->current;

    my $argv = @ARGV
        ? LIST->new([
            map STRING->new($_), @ARGV[1..$#ARGV]]
        ) : NIL->new;

    # Define these functions first for bootstrapping:
    $env->set(cons => \&Lingy::Lang::RT::cons);
    $env->set(concat => \&Lingy::Lang::RT::concat);
    $env->set(eval => sub { Lingy::Eval::eval($_[0], $env) });

    # Clojure dynamic vars:
    $env->set('*file*', STRING->new(
        $ARGV[0] || "NO_SOURCE_PATH"
    ));
    $env->set('*command-line-args*', $argv);

    # Lingy dynamic vars:
    $env->set('*ARGV*', $argv);
    $env->set('*LANG*', STRING->new($self->LANG));
    $env->set('*HOST*', STRING->new($self->HOST));

    $Lingy::VERSION =~ /^(\d+)\.(\d+)\.(\d+)$/;
    $self->rep("
      (def *lingy-version*
        {
          :major       $1
          :minor       $2
          :incremental $3
          :qualifier   nil
        })

      (def *clojure-version*
        {
          :major       1
          :minor       11
          :incremental 1
          :qualifier   nil
        })
    ");

    my $core_ly = $INC{'Lingy/Lang/RT.pm'};
    $core_ly =~ s/Lang\/RT\.pm$/core.ly/;
    $self->rep($self->slurp_file($core_ly));

    return $ns;
}

sub user_namespace {
    my ($self) = @_;

    Lingy::Namespace->new(
        name => 'user',
        refer => [
            $self->core,
        ],
    );
}

sub require_new {
    my $self = shift;
    my $class = shift;
    eval "require $class; 1" or
        die "Can't require '$class':\n$@";
    $class->new(@_);
}

sub slurp_file {
    my ($self, $file) = @_;
    open my $slurp, '<', "$file" or
        die "Couldn't read file '$file'";
    local $/;
    <$slurp>;
}

sub rep {
    my ($self, $str) = @_;
    map $pr_str->(Lingy::Eval::eval($_, $env)),
        $reader->read_str($str);
}

sub repl {
    my ($self) = @_;

    $self->rep(q< (println (str *LANG* " " (lingy-version) " [" *HOST* "]\n"))>)
        unless $ENV{LINGY_TEST};
    my ($clojure_repl) = $self->rep("(identity *clojure-repl*)");
    if ($clojure_repl eq 'true') {
        require Lingy::ClojureREPL;
        Lingy::ClojureREPL->start();
    }

    while (defined (my $line = Lingy::ReadLine::readline)) {
        next unless length $line;

        my @forms = eval { $reader->read_str($line, 1) };
        if ($@) {
            print "$@\n";
            $Lingy::ReadLine::input = '';
            next;
        }

        for my $form (@forms) {
            my $ret = eval { $pr_str->(Lingy::Eval::eval($form, $env)) };
            my $err;
            $err = $ret = $@ if $@;
            chomp $ret;
            print "$ret\n";
        }

        my $input = $Lingy::ReadLine::input // next;
        ($clojure_repl) = $self->rep("(identity *clojure-repl*)");

        if ($input =~ s/^;;;// or $clojure_repl eq 'true') {
            require Lingy::ClojureREPL;
            Lingy::ClojureREPL->rep($input);
        }
    }
    print "\n";
}


#------------------------------------------------------------------------------
our $nextID = 1000;

sub all_ns {
    list([
        map { $Lingy::Lang::RT::ns{$_} }
        sort keys %Lingy::Lang::RT::ns
    ]);
}

sub apply {
    my ($fn, $args) = @_;
    my $seq = pop(@$args);
    $seq = list([]) if ref($seq) eq NIL;
    push @$args, @$seq;
    ref($fn) eq 'CODE'
        ? $fn->(@$args)
        : Lingy::Eval::eval($fn->(@$args));
}

sub assoc {
    my ($map, $key, $val) = @_;
    $map->assoc($key, $val);
}

sub atom_ { atom($_[0]) }

sub booleanCast {
    my ($val) = @_;
    my $type = ref($val);
    $type eq NIL ? false :
    ($type eq BOOLEAN and $$val == 0) ? false :
    true;
}

sub charCast {
    my ($char) = @_;
    my $type = ref($char);
    err "Class '$type' cannot be cast to 'lingy.lang.Character'"
        unless $type eq SYMBOL or $type eq NUMBER;
    return CHARACTER->read($char);
}

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

sub contains {
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
        refer => Lingy::Lang::RT->core,
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

sub find_ns {
    assert_args(\@_, SYMBOL);
    $Lingy::Lang::RT::ns{$_[0]} // nil;
}

sub first {
    ref($_[0]) eq NIL
        ? nil : @{$_[0]} ? $_[0]->[0] : nil;
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
    my $ns = $Lingy::Lang::RT::ns{$name} //
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

sub list_ { list([@_]) }

sub macroexpand {
    Lingy::Eval::macroexpand($_[0], $Lingy::Eval::ENV);
}

sub map {
    list([
        map apply($_[0], [$_, []]), @{$_[1]}
    ]);
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

sub nextID {
    string(++$nextID);
}

sub ns_ {
    my ($name, $args) = @_;
    err "Invalid ns name '$name'"
        unless $name =~ /^\w+(\.\w+)*$/;

    my $ns;
    $ns = $Lingy::Lang::RT::ns{$name} //
    Lingy::Namespace->new(
        name => $name,
        refer => Lingy::Lang::RT->core,
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
    my @forms = $Lingy::Lang::RT::reader->read_str($_[0]);
    return @forms ? $forms[0] : nil;
}

sub readline {
    require Lingy::ReadLine;
    my $l = Lingy::ReadLine::readline() // return;
    chomp $l;
    string($l);
}

sub refer_ {
    my (@specs) = @_;
    for my $spec (@specs) {
        err "'refer' only works with symbols"
            unless ref($spec) eq SYMBOL;
        my $refer_ns_name = $$spec;
        my $current_ns_name = $Lingy::Lang::RT::ns;
        my $refer_ns = $Lingy::Lang::RT::ns{$refer_ns_name}
            or err "No namespace: '$refer_ns_name'";
        my $refer_map = $Lingy::Lang::RT::refer{$current_ns_name} //= {};
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

        return nil if $Lingy::Lang::RT::ns{$$spec};

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
                        refer => Lingy::Lang::RT->core,
                    );
                }
                if (-f "$inc_path.ly") {
                    my $ns = $Lingy::Lang::RT::ns{$Lingy::Lang::RT::ns};
                    Lingy::Lang::RT->rep(qq< (load-file "$inc_path.ly") >);
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
        $ns_name = $Lingy::Lang::RT::ns;
        $sym_name = $symbol;
    }

    my $ns = $Lingy::Lang::RT::ns{$ns_name} or return nil;
    if (exists $ns->{$sym_name}) {
        $var = $ns_name . '/' . $sym_name;
    } else {
        my $ref;
        if (($ref = $Lingy::Lang::RT::refer{$ns_name}) and
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

sub slurp { string(Lingy::Lang::RT->slurp_file($_[0])) }

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

sub swap_BANG {
    my ($atom, $fn, $args) = @_;
    $atom->[0] = apply($fn, [[$atom->[0], @$args]]);
}

sub symbol_ { symbol("$_[0]") }

sub the_ns {
    $_[0]->isa('Lingy::Namespace') ? $_[0] :
    $_[0]->isa(SYMBOL) ? do {
        $Lingy::Lang::RT::ns{$_[0]} //
        err "No namespace: '$_[0]' found";
    } : err "Invalid argument for the-ns: '$_[0]'";
}

sub time_ms {
    require Time::HiRes;
    my ($s, $m) = Time::HiRes::gettimeofday();
    number($s * 1000 + $m / 1000);
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

1;

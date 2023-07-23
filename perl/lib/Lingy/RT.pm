use strict; use warnings;
package Lingy::RT;

use Cwd;

use Lingy;
use Lingy::Common;
use Lingy::Evaluator;
use Lingy::Namespace;
use Lingy::ReadLine;

use constant LANG => 'Lingy';
use constant HOST => 'perl';

use constant env_class => 'Lingy::Env';
use constant printer_class => 'Lingy::Printer';
use constant reader_class => 'Lingy::Reader';
use constant RL => Lingy::ReadLine->new;

my @class_names = (
    ATOM,
    BOOLEAN,
    CHARACTER,
    CLASS,
    CLOJURE,
    COMPILER,
    EXCEPTION,
    FUNCTION,
    HASHMAP,
    HASHSET,
    KEYWORD,
    LIST,
    LAZYSEQ,
    LISTTYPE,
    LONGRANGE,
    MACRO,
    NIL,
    NUMBER,
    REGEX,
    SEQUENTIAL,
    STRBUILD,
    STRING,
    SYMBOL,
    SYSTEM,
    VAR,
    VECTOR,
    NUMBERS,
    RT,
    TERM,
    THREAD,
    UTIL,

    ILLEGALARGUMENTEXCEPTION,
);
sub class_names { \@class_names }

my $current_ns_name;
sub current_ns_name { $current_ns_name = $_[1] // $current_ns_name }

my %namespaces;
bless \%namespaces, 'lingy-internal';
sub namespaces { \%namespaces }
sub current_ns { $namespaces{$current_ns_name} }

my %classes;
sub classes { \%classes }

my %meta;
sub meta { \%meta }

my $env;
sub env { $env }
sub ENV { $Lingy::Evaluator::ENV }

my $reader;
sub reader { $reader }

my $printer;
sub printer { $printer }

my $core_ns;
sub core_ns { $core_ns }

my $user_ns;
sub user_ns { $user_ns }

our $OK = 0;

sub init {
    my ($self) = @_;

    for my $package_name (@{RT->class_names}) {
        eval "require $package_name; 1" or die $@;
        my $class = CLASS->_new($package_name);
        my $class_name = $class->_name;
        $classes{$class_name} = $class;
        if ($class_name =~ /\.(\w+)$/) {
            $classes{$1} = $class;
        }
    }

    $env     = $self->require_new($self->env_class);
    $reader  = $self->require_new($self->reader_class);
    $printer = $self->require_new($self->printer_class);

    $core_ns = $self->core_namespace();
    $user_ns = NAMESPACE->new('user')
        ->refer(symbol($self->core_ns->_name))
        ->current;

    $OK = 1;

    return $self;
}

sub core_namespace {
    my ($self) = (@_);

    my $ns = NAMESPACE->new('lingy.core', %classes)->current;

    $ns->{$_} = $classes{$_} for CORE::keys %classes;

    my $argv = @ARGV
        ? LIST->new([
            map STRING->new($_), @ARGV[1..$#ARGV]]
        ) : NIL->new;

    # Define these functions first for bootstrapping:
    $env->set(cons => \&cons);
    $env->set(concat => \&concat);
    $env->set(eval => sub { evaluate($_[0], $env) });

    # Clojure dynamic vars:
    my $file = $ARGV[0] || "NO_SOURCE_PATH";
    $file = Cwd::abs_path($file) unless $file eq "NO_SOURCE_PATH";
    $env->set('*file*', STRING->new($file));
    $env->set('*command-line-args*', $argv);

    # Lingy dynamic vars:
    $env->set('*LANG*', STRING->new($self->LANG));
    $env->set('*HOST*', STRING->new($self->HOST));

    # Work around a bug in version checking during cpanm install:
    my $v = $Lingy::VERSION;
    $v =~ /^(\d+)\.(\d+)\.(\d+)$/;

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

    my $core_ly = $INC{'Lingy/RT.pm'};
    $core_ly =~ s/RT\.pm$/core.ly/;
    $self->rep($self->slurp_file($core_ly));

    unless ($ENV{LINGY_BUILDING_CORE}) {
        my $core_clj = $core_ly;
        $core_clj =~ s/\.ly$/.clj/;
        $self->rep($self->slurp_file($core_clj));
    }

    return $ns;
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

sub is_lingy_class {
    my ($self, $class) = @_;
    $class->isa(CLASS) or $class =~ /^Lingy::\w/;
}

sub eval {
    my ($self, $form) = @_;
    evaluate(
        $form,
        $env,
    );
}

sub rep {
    my ($self, $str) = @_;
    map $printer->pr_str(evaluate($_, $env)),
        $reader->read_str($str);
}

use constant repl_intro_command =>
    q<(println (str *LANG* " " (lingy-version) " [" *HOST* "]\n"))>;

sub repl {
    my ($self) = @_;

    $self->RL->setup;

    $self->rep($self->repl_intro_command)
        unless $ENV{LINGY_TEST};
    my ($clojure_repl) = $self->rep("(identity *clojure-repl*)");
    if ($clojure_repl eq 'true') {
        require Lingy::ClojureREPL;
        Lingy::ClojureREPL->start();
    }

    while (defined (my $line = $self->RL->readline)) {
        next unless length $line;

        my @forms = eval { $reader->read_str($line, 1) };
        if ($@) {
            print "$@\n";
            $self->RL->input;
            next;
        }

        for my $form (@forms) {
            my $ret = eval {
                $printer->pr_str(evaluate($form, $env));
            };
            my $err;
            $err = $ret = $@ if $@;
            chomp $ret;
            print "$ret\n";
        }

        my $input = $self->RL->input // next;
        ($clojure_repl) = $self->rep("(identity *clojure-repl*)");

        if ($input =~ s/^;;;// or $clojure_repl eq 'true') {
            require Lingy::ClojureREPL;
            Lingy::ClojureREPL->rep($input);
        }
    }
    print "\n";
}


#------------------------------------------------------------------------------

sub all_ns {
    list([
        map { $namespaces{$_} }
        sort CORE::keys %namespaces
    ]);
}

sub apply {
    my ($fn, $args) = @_;
    my $seq = pop(@$args);
    $seq = list([]) if ref($seq) eq NIL;
    push @$args, @$seq;
    ref($fn) eq 'CODE'
        ? $fn->(@$args)
        : evaluate($fn->(@$args));
}

sub applyTo {
    my ($obj, $meth, $args) = @_;
    $meth = "$meth";
    my @args = map unbox_val(evaluate($_, ENV())), @$args;
    box_val $obj->$meth(@args);
}

sub assoc {
    my ($map, $key, $val) = @_;
    $map->assoc($key, $val);
}

sub atom { ATOM->new($_[0]) }

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
    $type eq VECTOR ? VECTOR->new([@$o, @args]) :
    $type eq HASHMAP ? HASHMAP->new([%$o, map %$_, @args]) :
    $type eq NIL ? nil :
    err("conj first arg type '$type' not allowed");
}

sub cons { list([$_[0], @{$_[1]}]) }

sub contains {
    my ($map, $key) = @_;
    return false unless ref($map) eq HASHMAP;
    $key =
        $key->isa(STRING) ? qq<"$key> :
        $key->isa(SYMBOL) ? qq<$key > :
        "$key";
    BOOLEAN->new(exists $map->{"$key"});
}

sub count {
    NUMBER->new(ref($_[0]) eq NIL ? 0 : scalar @{$_[0]});
}

sub create_ns {
    my ($name) = @_;
    err "Invalid ns name '$name'"
        unless $name =~ /^\w+(\.\w+)*$/;
    NAMESPACE->new($name)->refer(symbol($core_ns->_name));
}

sub deref { $_[0]->[0] }

sub dissoc {
    my ($map, @keys) = @_;
    @keys = map {
        $_->isa(STRING) ? qq<"$_> : "$_";
    } @keys;
    $map = { %$map };
    delete $map->{$_} for @keys;
    HASHMAP->new([%$map]);
}

sub eval_perl {
    my ($perl) = @_;
    my $ret = eval "$perl";
    err("$@") if $@;
    return $ret;
}

sub find_ns {
    assert_args(\@_, SYMBOL);
    $namespaces{$_[0]} // nil;
}

sub first {
    ref($_[0]) eq NIL
        ? nil : @{$_[0]} ? $_[0]->[0] : nil;
}

sub get {
    my ($map, $key, $default) = @_;
    return nil unless ref($map) eq HASHMAP or ref($map) eq HASHSET;
    $key = qq<"$key> if $key->isa(STRING);
    $map->{"$key"} // $default // nil;
}

sub getenv {
    my $val = $ENV{$_[0]};
    defined($val) ? string($val) : nil;
}

sub hash_map { HASHMAP->new([@_]) }

sub hash_set { HASHSET->new([@_]) }

sub in_ns {
    my ($name) = @_;
    err "Invalid ns name '$name'"
        unless $name =~ /^\w+(\.\w+)*$/;
    my $ns = $namespaces{$name} // NAMESPACE->new($name);
    $ns->current;
}

sub keys {
    list([
        map {
            s/^"// ? string($_) :
            s/^:// ? KEYWORD->new($_) :
            s/ $// ? symbol($_) :
            symbol("$_");
        } CORE::keys %{$_[0]}
    ]);
}

sub keyword { KEYWORD->new($_[0]) }

sub list_ { list([@_]) }

sub macroexpand {
    Lingy::Evaluator::macroexpand($_[0], $Lingy::Evaluator::ENV);
}

sub map {
    list([
        map apply($_[0], [$_, []]), @{$_[1]}
    ]);
}

sub meta_get {
    $meta{"$_[0]"} // nil;
}

sub more {
    my ($list) = @_;
    return LIST->EMPTY if $list->isa(NIL) or not @$list;
    list([@{$list}[1..(@$list-1)]]);
}

sub name {
    string($_[0] =~ m{(.*?)/(.*)} ? $2 : "$_[0]");
}

sub namespace {
    $_[0] =~ m{(.*?)/(.*)} ? string($1) : nil;
}

my $nextID = 1000;
sub nextID {
    return $nextID = $_[1] if @_ == 2;
    string(++$nextID);
}

sub ns {
    my ($name, $args) = @_;
    err "Invalid ns name '$name'"
        unless $name =~ /^\w+(?:\.\w+)*$/;

    my $ns;
    $ns = $namespaces{$name} //
    NAMESPACE->new($name)->refer(symbol($core_ns->_name));
    $ns->current;

    for my $arg (@$args) {
        err "Invalid ns arg" unless
            $arg->isa(LIST) and
            @$arg >= 2 and
            ref($arg->[0]) eq KEYWORD;

        my ($keyword, @args) = @$arg;
        if ($$keyword eq ':use') {
            for my $spec (@args) {
                evaluate(
                    list([
                        symbol('use'),
                        list([symbol('quote'), $spec]),
                    ]),
                    $Lingy::Evaluator::ENV,
                );
            }
        }
        elsif ($$keyword eq ':import') {
            my (undef, @args) = @$arg;
            evaluate(
                list([ symbol('import'), @args ]),
                $Lingy::Evaluator::ENV,
            );
        }
        else {
            err "Invalid keyword arg '$keyword' in ns";
        }
    }

    nil;
}

sub nth { $_[0][$_[1]] }

sub number { NUMBER->new("$_[0]" + 0) }

sub pos_Q { $_[0] > 0 ? true : false }

sub pr_str {
    string(join ' ', map $printer->pr_str($_), @_);
}

sub println {
    printf "%s\n", join ' ',
        map $printer->pr_str($_, 1), @_;
    nil;
}

sub prn {
    printf "%s\n", join ' ',
    map $printer->pr_str($_), @_;
    nil;
}

sub readString {
    my @forms = Lingy::Reader->new->read_str($_[0]);
    return @forms ? $forms[0] : nil;
}

sub readline {
    my $l = RL->readline // return;
    chomp $l;
    string($l);
}

our $require_ext = 'ly';
sub require {
    outer:
    for my $spec (@_) {
        err "'require' only works with symbols"
            unless ref($spec) eq SYMBOL;

        next if $namespaces{$$spec};

        my $name = $$spec;

        my $path = $name;
        $path =~ s/^lingy\.lang\./Lingy./;
        $path =~ s/^lingy\./Lingy\./;
        my $module = $path;
        $path =~ s/\./\//g;

        for my $inc (@INC) {
            $inc =~ s{^([^/.])}{./$1};
            my $inc_path = "$inc/$path";
            if (-f "$inc_path.$require_ext") {
                my $ns = $namespaces{$current_ns_name};
                RT->rep(qq< (load-file "$inc_path.$require_ext") >);
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
        $ns_name = $current_ns_name;
        $sym_name = $symbol;
    }

    my $ns = $namespaces{$ns_name} or return nil;
    if (exists $ns->{$sym_name}) {
        $var = $ns_name . '/' . $sym_name;
    } else {
        return nil;
    }
    return VAR->new($var);
}

sub seq {
    my ($o) = @_;
    $o->can('_to_seq') or
        err(sprintf "Don't know how to create ISeq from: %s", $o->NAME);  # XXX NAME is Class name not namespace
    $o->_to_seq;
}

sub slurp { string(RT->slurp_file($_[0])) }

sub sort {
    list([
        CORE::sort @{$_[0]}
    ]);
}

sub str {
    string(
        join '',
            map $printer->pr_str($_, 1),
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
    $_[0]->isa(NAMESPACE) ? $_[0] :
    $_[0]->isa(SYMBOL) ? do {
        $namespaces{$_[0]} //
        err "No namespace: '$_[0]' found";
    } : err "Invalid argument for the-ns: '$_[0]'";
}

sub time_ms {
    require Time::HiRes;
    my ($s, $m) = Time::HiRes::gettimeofday();
    NUMBER->new($s * 1000 + $m / 1000);
}

sub type {
    CLASS->_new(ref($_[0]));
}

sub with_meta {
    my ($o, $m) = @_;
    $o = ref($o) eq 'CODE' ? sub { goto &$o } : $o->clone;
    $meta{$o} = $m;
    $o;
}

sub vals { list([ values %{$_[0]} ]) }

sub var_ { VAR->new($_[0]) }

sub vec { VECTOR->new([@{$_[0]}]) }

sub vector { VECTOR->new([@_]) }

1;

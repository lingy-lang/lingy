use strict; use warnings;
package Lingy::Main;

use Lingy::Common;

use Lingy;
use Lingy::Eval;
use Lingy::Lang::Class;
use Lingy::Namespace();
use Lingy::ReadLine;

use Lingy::Lang::HashMap;
use Lingy::Lang::Nil;
use Lingy::Lang::Symbol;

use constant LANG => 'Lingy';
use constant HOST => 'perl';

use constant env_class => 'Lingy::Env';
use constant printer_class => 'Lingy::Printer';
use constant reader_class => 'Lingy::Reader';
use constant util_class => 'Lingy::Util';

our $ns = '';               # Current namespace name
our %ns = ();               # Map of all namespaces
our %refer = ();            # Map of all namespace refers
bless \%ns, 'lingy-internal';
bless \%refer, 'lingy-internal';

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
    MACRO,
    NIL,
    NUMBER,
    REGEX,
    STRING,
    SYMBOL,
    VAR,
    VECTOR,
    NUMBERS,
    RT,
    TERM,
    THREAD,
);

# Preload classes:
our %class = map {
    my $class = CLASS->_new($_);
    ($class->_name, $class);
} @class;

our ($env, $reader, $printer);
our ($rt, $core, $util, $user);

my $pr_str;

sub rt { $rt }
sub ns { \%ns }
sub NS { $ns{$ns} }
sub refer { \%refer }
sub env { $env }
sub core { $core }
sub util { $util }
sub user { $user }

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
    $util    = $self->require_new($self->util_class);

    $pr_str = $printer->can('pr_str') or die;

    $core = $self->core_namespace();
    $user = $self->user_namespace();

    $user->current;

    $Lingy::Main::ready = 1;

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

    my $core_ly = $INC{'Lingy/Main.pm'};
    $core_ly =~ s/Main\.pm$/core.ly/;
    $self->rep($self->slurp($core_ly));

    return $ns;
}

sub user_namespace {
    my ($self) = @_;

    Lingy::Namespace->new(
        name => 'user',
        refer => [
            $self->core,
            $self->util,
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

sub slurp {
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

1;

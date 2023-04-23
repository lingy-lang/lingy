use strict; use warnings;
package Lingy::RT;

use Lingy::Eval;
use Lingy::Lang::Class;
use Lingy::Lang::List;
use Lingy::Lang::String;
use Lingy::Namespace();
use Lingy::ReadLine;

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
    'Lingy::Lang::Atom',
    'Lingy::Lang::Boolean',
    'Lingy::Lang::Class',
    'Lingy::Lang::Character',
    'Lingy::Lang::Function',
    'Lingy::Lang::HashMap',
    'Lingy::Lang::Keyword',
    'Lingy::Lang::List',
    'Lingy::Lang::Macro',
    'Lingy::Lang::Nil',
    'Lingy::Lang::Number',
    'Lingy::Lang::Macro',
    'Lingy::Lang::Numbers',
    'Lingy::Lang::Regex',
    'Lingy::Lang::RT',
    'Lingy::Lang::String',
    'Lingy::Lang::Symbol',
    'Lingy::Lang::Term',
    'Lingy::Lang::Thread',
    'Lingy::Lang::Var',
    'Lingy::Lang::Vector',
);

# Preload classes:
our %class = map {
    my $class = Lingy::Lang::Class->_new($_);
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

    $Lingy::RT::ready = 1;

    return $self;
}

sub core_namespace {
    my ($self) = @_;

    my $ns = Lingy::Namespace->new(
        name => 'lingy.core',
    )->current;

    my $argv = @ARGV
        ? Lingy::Lang::List->new([
            map Lingy::Lang::String->new($_), @ARGV[1..$#ARGV]]
        ) : Lingy::Lang::Nil->new;

    # Define these fns first for bootstrapping:
    $env->set(cons => \&Lingy::Lang::RT::cons);
    $env->set(concat => \&Lingy::Lang::RT::concat);
    $env->set(eval => sub { Lingy::Eval::eval($_[0], $env) });

    # Clojure dynamic vars:
    $env->set('*file*', Lingy::Lang::String->new(
        $ARGV[0] || "NO_SOURCE_PATH"
    ));
    $env->set('*command-line-args*', $argv);

    # Lingy dynamic vars:
    $env->set('*ARGV*', $argv);
    $env->set('*LANG*', Lingy::Lang::String->new($self->LANG));
    $env->set('*HOST*', Lingy::Lang::String->new($self->HOST));

    my $core_ly = $INC{'Lingy/RT.pm'};
    $core_ly =~ s/RT\.pm$/core.ly/;
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
    my ($self, $str, $repl) = @_;
    my @ret;
    for ($reader->read_str($str, $repl)) {
        if ($repl) {
            my $ret = eval { $pr_str->(Lingy::Eval::eval($_, $env)) };
            $ret = $@ if $@;
            chomp $ret;
            print "$ret\n";
        } else {
            push @ret, $pr_str->(Lingy::Eval::eval($_, $env));
        }
    }
    return @ret;
}

sub repl {
    my ($self) = @_;
    $self->rep(q< (println (str "Welcome to " *LANG* " [" *HOST* "]\n"))>)
        unless $ENV{LINGY_TEST};
    while (defined (my $line = Lingy::ReadLine::readline)) {
        next unless length $line;
        eval { $self->rep("$line", 'repl') };
        print $@ if $@;
    }
    print "\n";
}

1;

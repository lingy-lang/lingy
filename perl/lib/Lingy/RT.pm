use strict; use warnings;
package Lingy::RT;

use Lingy::Eval;
use Lingy::Lang::Class;
use Lingy::Lang::List;
use Lingy::Lang::String;
use Lingy::Namespace();
use Lingy::ReadLine;

use constant host => 'perl';

our $env_class = 'Lingy::Env';
our $printer_class = 'Lingy::Printer';
our $reader_class = 'Lingy::Reader';

our $util_class = 'Lingy::Util';

our $ns = '';               # Current namespace name
our %ns = ();               # Map of all namespaces
our %refer = ();            # Map of all namespace refers

sub class { Lingy::Lang::Class->_new(@_) }

our %class = (              # Preload lingy.lang.Xyz classes:
    'lingy.lang.Atom'       => class('Lingy::Lang::Atom'),
    'lingy.lang.Boolean'    => class('Lingy::Lang::Boolean'),
    'lingy.lang.Class'      => class('Lingy::Lang::Class'),
    'lingy.lang.Function'   => class('Lingy::Lang::Function'),
    'lingy.lang.HashMap'    => class('Lingy::Lang::HashMap'),
    'lingy.lang.Keyword'    => class('Lingy::Lang::Keyword'),
    'lingy.lang.List'       => class('Lingy::Lang::List'),
    'lingy.lang.Macro'      => class('Lingy::Lang::Macro'),
    'lingy.lang.Nil'        => class('Lingy::Lang::Nil'),
    'lingy.lang.Number'     => class('Lingy::Lang::Number'),
    'lingy.lang.Macro'      => class('Lingy::Lang::Macro'),
    'lingy.lang.Numbers'    => class('Lingy::Lang::Numbers'),
    'lingy.lang.RT'         => class('Lingy::Lang::RT'),
    'lingy.lang.String'     => class('Lingy::Lang::String'),
    'lingy.lang.Symbol'     => class('Lingy::Lang::Symbol'),
    'lingy.lang.Var'        => class('Lingy::Lang::Var'),
    'lingy.lang.Vector'     => class('Lingy::Lang::Vector'),
);

our ($env, $reader, $printer);
our ($util);
our ($core, $user);

my $pr_str;

sub init {
    for my $class (keys %class) {
        my $package = $class{$class};
        eval "require $package";
        die $@ if $@;
        if ($class =~ /\.(\w+)$/) {
            $class{$1} = $package;
        }
    }

    $env     = require_new($env_class);
    $reader  = require_new($reader_class);
    $printer = require_new($printer_class);
    $util    = require_new($util_class);

    $pr_str = $printer->can('pr_str') or die;

    $core = core_namespace();

    $user = Lingy::Namespace->new(
        name => 'user',
        refer => [
            $core->NAME,
            $util->NAME,
        ],
    )->current;

    return shift;
}

sub core_namespace {
    my $ns = Lingy::Namespace->new(
        name => 'lingy.core',
        delay => 1,
    )->current;

    my $argv = @ARGV
        ? Lingy::Lang::List->new([
            map Lingy::Lang::String->new($_), @ARGV[1..$#ARGV]]
        ) : Lingy::Lang::Nil->new;

    # Define these fns first for bootstrapping:
    $env->set(cons => \&Lingy::Lang::RT::cons);
    $env->set(concat => \&Lingy::Lang::RT::concat);
    $env->set(eval => sub { Lingy::Eval::eval($_[0], $env) });

    $env->set('*file*', Lingy::Lang::String->new(
        $ARGV[0] || "NO_SOURCE_PATH"
    ));
    $env->set('*ARGV*', $argv);
    $env->set('*command-line-args*', $argv);
    $env->set('*host*', Lingy::Lang::String->new(host));

    my $core_ly = $INC{'Lingy/RT.pm'};
    $core_ly =~ s/RT\.pm$/core.ly/;
    Lingy::RT->rep(slurp($core_ly));

    return $ns;
}

sub require_new {
    my $class = shift;
    eval "require $class; 1" or
        die "Can't require '$class':\n$@";
    $class->new(@_);
}

sub slurp {
    my ($file) = @_;
    open my $slurp, '<', "$file" or
        die "Couldn't read file '$file'";
    local $/;
    <$slurp>;
}

sub rep {
    my ($self, $str, $prn) = @_;
    my @ret;
    for ($reader->read_str($str)) {
        if ($prn) {
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
    $self->rep(q< (println (str "Welcome to Lingy [" *host* "]\n"))>)
        unless $ENV{LINGY_TEST};
    while (defined (my $line = Lingy::ReadLine::readline)) {
        next unless length $line;
        eval { $self->rep("$line", 'prn') };
        print $@ if $@;
    }
    print "\n";
}

1;

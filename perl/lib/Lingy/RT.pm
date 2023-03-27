use strict; use warnings;
package Lingy::RT;

use Lingy::ReadLine;

use constant host => 'perl';

our $env_class = 'Lingy::Env';
our $printer_class = 'Lingy::Printer';
our $reader_class = 'Lingy::Reader';

our $core_class = 'Lingy::Core';
our $numbers_class = 'Lingy::Lang::Numbers';
our $rt_class = 'Lingy::Lang::RT';
our $util_class = 'Lingy::Lang::Util';

our $ns = '';               # Current namespace (*ns*)
our %ns = ();               # Map of all namespaces
our %refer = ();            # Map of all namespace refers

our ($env, $reader, $printer);
our ($numbers, $rt, $util);
our ($core, $user);

my $pr_str;

sub init {
    $env        = require_new($env_class);
    $reader     = require_new($reader_class);
    $printer    = require_new($printer_class);

    $pr_str = $printer->can('pr_str') or die;

    $numbers    = require_new($numbers_class);
    $rt         = require_new($rt_class);
    $util       = require_new($util_class);

    $core = require_new($core_class, delay => 1)->current->init;

    $user = Lingy::NS->new(
        name => 'user',
        refer => [
            $core->name,
            $rt->name,
            $util->name,
        ],
    )->current;

    return shift;
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

sub require_new {
    my $class = shift;
    eval "require $class; 1" or
        die "Can't require '$class':\n$@";
    $class->new(@_);
}

1;

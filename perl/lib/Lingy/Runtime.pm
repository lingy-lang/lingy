use strict; use warnings;
package Lingy::Runtime;

use Lingy::Eval ();
use Lingy::ReadLine 'readline';
use Lingy::Types;

our $core_class = 'Lingy::Core';
our $env_class = 'Lingy::Env';
our $printer_class = 'Lingy::Printer';
our $reader_class = 'Lingy::Reader';

our $host = 'perl';
our $rt;                    # Lingy::Runtime singleton instance
our $ns = 'lingy.core';     # Current namespace (*ns*)
our %ns = ();               # Map of all namespaces

our $prompt;
my ($core, $env, $printer, $pr_str, $reader);

sub core { $core }
sub env { $env }
sub printer { $printer }
sub prompt { $prompt }
sub reader { $reader }

sub require_new {
    my $class = shift;
    eval "require $class; 1" or
        die "Can't 'require $class': $@";
    $class->new(@_);
}

sub new {
    my $class = shift;

    my $self = $rt = bless {}, $class;

    $prompt = 'user> ';
    $env = require_new($env_class);
    $reader = require_new($reader_class);
    $printer = require_new($printer_class);
    $pr_str = $printer->can('pr_str') or die;
    $core = require_new($core_class);
    $env->{space} = $core;
    $ns{$ns} = $core;
    $core->init;

    return $self;
}

sub rep {
    my ($self, $str) = @_;
    my @out;
    for my $form ($self->reader->read_str($str)) {
        my $ast = Lingy::Eval::eval($form, $self->env);
        push @out, $pr_str->($ast);
    }
    return @out;
}

sub repl {
    my ($self) = @_;

    $self->rep(q<
      (println
        (str "Welcome to Lingy [" *host* "]\n"))>);

    while (defined (my $line = readline)) {
        next unless length $line;
        eval {
            print "$_\n" for $self->rep("$line");
        };
        print "$@" if $@;
    }

    print "\n";
}

1;
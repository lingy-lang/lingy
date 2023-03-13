use strict; use warnings;
package Lingy::REPL;

use Lingy::Core;
use Lingy::Env;
use Lingy::Eval;
use Lingy::Printer;
use Lingy::ReadLine;
use Lingy::Reader;
use Lingy::Types;

use constant core_class => 'Lingy::Core';
use constant env_class => 'Lingy::Env';
use constant reader_class => 'Lingy::Reader';

sub prompt { $_[0]->{prompt} }
sub env { $_[0]->{env} }
sub reader { $_[0]->{reader} }

sub new {
    my $class = shift;
    my $self = bless {
        prompt => 'user> ',
        env => $class->env_class->new(
            stash => $class->core_class->ns,
        ),
        reader => $class->reader_class->new,
        @_,
    }, $class;
    $self->init;
    return $self;
}

sub init {
    my ($self) = @_;
    $self->env->set('*ARGV*', list([map string($_), @ARGV[1..$#ARGV]]));
    $self->env->set(eval => sub { Lingy::Eval::eval($_[0], $self->env) });

    $self->rep(q<
      (defmacro! defmacro
        (fn* (name args body)
          `(defmacro! ~name (fn* ~args ~body)))) >);

    $self->rep(q< (defmacro def (& xs) (cons 'def! xs)) >);
    $self->rep(q< (defmacro fn (& xs) (cons 'fn* xs)) >);

    $self->rep(q<
      (defmacro defn (name args body)
        `(def ~name (fn ~args ~body))) >);

    $self->rep(q< (defmacro let (& xs) (cons 'let* xs)) >);
    $self->rep(q< (defmacro try (& xs) (cons 'try* xs)) >);

    $self->rep('
      (defn not (a)
        (if a
          false
          true))');

    $self->rep(q[
      (defmacro cond (& xs)
        (if (> (count xs) 0)
          (list 'if (first xs)
            (if (> (count xs) 1)
              (nth xs 1)
              (throw "odd number of forms to cond"))
            (cons 'cond (rest (rest xs))))))]);

    $self->rep('
      (defn load-file (f)
        (eval
          (read-string
            (str
              "(do "
              (slurp f)
              "\nnil)"    ))))');

    $self->env->set('*file*', string($ARGV[0]));
    $self->rep('(def *host-language* "perl")');
}

sub repl {
    my ($self) = @_;

    $self->rep(q<
      (println
        (str
          "Welcome to Lingy ["
          *host-language*
          "]\n"   )) >);

    while (defined (my $line = readline($self->prompt, $self->env))) {
        $self->try($line) if length $line;
    }

    print "\n";
}

sub try {
    my ($self, $line) = @_;
    eval { print $self->rep("$line") . "\n" };
    if ($@) {
        die $@ if $@ =~ /(^>>|^---\s| via package ")/;
        print "Error: " .
            (ref($@) ? Lingy::Printer::pr_str($@) : $@) .
            "\n";
    }
}

sub rep {
    my ($self, $str) = @_;
    my $ast = $self->reader->read_str($str);
    $ast = Lingy::Eval::eval($ast, $self->env);
    Lingy::Printer::pr_str($ast);
}

1;

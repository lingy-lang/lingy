use strict; use warnings;
package Lingy::Evaluator;

use Lingy::Common;

use Exporter 'import';

our @EXPORT = qw(
    evaluate
);

# Lingy Special Forms:
my %special_dispatch = (
    'def'               => \&special_def,
    'defmacro!'         => \&special_defmacro,
    'do'                => \&special_do,
    '.'                 => \&special_dot,
    'fn*'               => \&special_fn,
    'if'                => \&special_if,
    'import*'           => \&special_import,
    'let*'              => \&special_let,
    'loop'              => \&special_loop,
    'new'               => \&special_new,
    'recur'             => \&special_recur,
    'quasiquote'        => \&special_quasiquote,
    'quasiquoteexpand'  => \&special_quasiquoteexpand,
    'quote'             => \&special_quote,
    'try*'              => \&special_try,
    'throw'             => \&special_throw,
    'var'               => \&special_var,
);

sub special_symbols {
    keys %special_dispatch;
}


# Main eval functions:
our $ENV;
sub evaluate {
    my ($ast, $env) = @_;
    $ENV = $env;

    while (1) {
        $ast = macroexpand($ast, $env);

        return evaluate_ast($ast, $env) unless ref($ast) eq LIST;

        return $ast unless @$ast;   # Empty list

        if (my $fn = $special_dispatch{$ast->[0]}) {
            ($ast, $env) = $fn->($ast, $env);
            return $ast unless $env;

        } else {
            my ($fn, @args) = @{evaluate_ast($ast, $env)};
            return $fn->(@args) if ref($fn) eq 'CODE';

            while ((my $ref = ref($fn)) ne FUNCTION) {
                if ($ref eq VAR) {
                    $fn = $env->get($$fn);

                } elsif ($ref eq KEYWORD) {
                    return special_keyword($env, $fn, @args);

                } elsif ($ref eq VECTOR) {
                    return special_vector($env, $fn, @args);

                } elsif ($ref eq NIL) {
                    return $args[0];

                } else {
                    err "Can't use '$ref' object as function";
                }
            }
            ($ast, $env) = $fn->(@args);
        }
    }
}

sub evaluate_ast {
    my ($ast, $env) = @_;
    $ast->isa(LISTTYPE)
        ? ref($ast)->new([ map evaluate($_, $env), @$ast ]) :
    $ast->isa(HASHMAP)
        ? ref($ast)->new([map evaluate($_, $env), %$ast]) :
    $ast->isa(SYMBOL)
        ? $env->get($$ast) :
    $ast;
}


# Special form handler functions:
sub special_def {
    my ($ast, $env) = @_;
    my (undef, $sym, $form) = @$ast;
    $sym // err "Too few arguments to def";
    $form //= nil;
    err "Can't def a qualified symbol: '$sym'"
        if $sym =~ m{./.};
    RT->current_ns->set($$sym, evaluate($form, $env));
}

sub special_defmacro {
    my ($ast, $env) = @_;
    my (undef, $sym, $form) = @$ast;
    RT->current_ns->set($$sym, MACRO->new(evaluate($form, $env)));
}

sub special_do {
    my ($ast, $env) = @_;
    my (undef, @do) = @$ast;
    $ast = pop @do;
    evaluate_ast(list(\@do), $env);
    return ($ast, $env);
}

# TODO This function needs more attention and testing.
sub special_dot {
    my ($ast, $env) = @_;

    my (undef, $target, @args) = @$ast;
    if (@args == 1 and ref($args[0]) eq LIST) {
        @args = @{$args[0]};
    }

    ($target, @args) = map {
        $_->isa(LIST)
            ? evaluate($_, $env) : $_;
    } ($target, @args);

    @args > 0 or err "Not enough args for . form";

    if (my $class = is_class_symbol($target)) {
        if (RT->is_lingy_class($class)) {
            $target = "${class}::${shift @args}";
            @args = map {
                $_->isa(SYMBOL) ? $env->get($_) : $_;
            } @args;
            no strict 'refs';
            return &{$target}(@args);
        }

        else {
            my $method = shift(@args) or die;
            $method->isa(SYMBOL) or die;
            $method = $$method;
            @args = map {
                unbox_val( $_->isa(SYMBOL) ? $env->get($_) : $_ );
            } @args;
            return box_val $class->$method(@args);
        }
    }

    $target = $env->get($target)
        if $target->isa(SYMBOL);

    if (@args) {
        my $member = shift(@args);
        if ($target->isa(CLASS)) {
            @args = map { $_->isa(SYMBOL)
                ? $env->get($_) : $_; } @args;

            if (not $target->can($member)) {
                my $class = $target->NAME;
                err "No matching field found: '$member' " .
                    "for class '$class'";
            }
            my $method = $$member;
            return $target->$method(@args);
        }

        # Test the unboxing of native call args:
        if ($target->can($member)) {
            my $method = $$member;
            @args = map {
                unbox_val( $_->isa(SYMBOL) ? $env->get($_) : $_ );
            } @args;
            return box_val $target->$method(@args);
        }
    }

    XXX $ast, "Don't know how to '.' this yet";
}

sub special_fn {
    my ($ast, $env) = @_;
    return FUNCTION->new($ast, $env);
}

sub special_if {
    my ($ast, $env) = @_;
    my (undef, $cond, $then, $else) = @$ast;
    $ast = ${BOOLEAN->new(evaluate($cond, $env))} ? $then :
        defined $else ? $else : nil;
    return ($ast, $env);
}

sub special_import {
    my ($ast, $env) = @_;

    my ($fn, @specs) = @$ast;

    my $return = nil;

    for my $spec (@specs) {
        if (ref($spec) eq SYMBOL) {
            $spec = list([$spec]);
        }

        err "Invalid import spec" unless
            $spec->isa(LIST) and
            @$spec > 0 and
            not grep { ref($_) ne SYMBOL } @$spec;

        my ($module_name, $imports) = @$spec;
        my $name = $$module_name;
        (my $module = $name) =~ s/lingy\.lang\./Lingy::/;
        $module =~ s/\./::/g;
        eval "require $module; 1" or die $@;
        my $class = RT->current_ns->{$name} =
            CLASS->_new($name);
        if ($module->can('new')) {
            $return = $class;
        }
        # TODO - imports
    }

    return $return;
}

sub special_keyword {
    my ($env, $keyword, @args) = @_;
    err "Wrong number of args (${\ scalar @args}) passed to: '$keyword'"
        unless @args == 1 or @args == 2;
    my $map = shift @args;
    evaluate(
        list([
            symbol('get'),
            $map,
            $keyword,
            @args,
        ]),
        $env,
    );
}

sub special_let {
    my ($ast, $env) = @_;
    my (undef, $bindings, $body) = @$ast;
    err "First argument to 'let' must be a vector"
        unless ref($bindings) eq VECTOR;
    $env = Lingy::Env->new(outer => $env);
    for (my $i = 0; $i < @$bindings; $i += 2) {
        $env->set(
            ${$bindings->[$i]},
            evaluate($bindings->[$i+1], $env),
        );
    }
    $body = list([symbol('do'), @{$ast}[2..(@$ast-1)] ])
        if @$ast > 3;
    return ($body, $env);
}

sub special_loop {
    my ($ast, $env) = @_;
    my (undef, $bindings, $body) = @$ast;
    if (not $env->{RECUR}) {
        err "First argument to 'loop' must be a vector"
            unless ref($bindings) eq VECTOR;
        $env = Lingy::Env->new(outer => $env);
        my $binds = [];
        for (my $i = 0; $i < @$bindings; $i += 2) {
            push @$binds, ${$bindings->[$i]};
            $env->set(
                ${$bindings->[$i]},
                evaluate($bindings->[$i+1], $env),
            );
        }
        $body //= nil;
        $body = list([symbol('do'), @{$ast}[2..(@$ast-1)] ])
            if @$ast > 3;
        $env->{LOOP} = [$binds, $body];
    } else {
        my $binds;
        ($binds, $body) = @{$env->{LOOP}};
        if (@$bindings != @$binds) {
            err sprintf
                "Mismatched argument count to recur, " .
                "expected: %d args, got: %d",
                scalar(@$binds),
                scalar(@$bindings);
        }
        my $i = 0;
        for my $bind (@$binds) {
            $env->set($bind, $bindings->[$i++], $env);
        }
    }
    return ($body, $env);
}

sub special_new {
    my ($ast, $env) = @_;
    XXX @_, 'special_new not yet implemented';
}

sub special_quasiquote {
    my ($ast, $env) = @_;
    return (quasiquote($ast->[1]), $env);
}

sub special_quasiquoteexpand {
    my ($ast, $env) = @_;
    return quasiquote($ast->[1]);
}

sub special_quote {
    my ($ast, $env) = @_;
    return $ast->[1];
}

sub special_recur {
    my ($ast, $env) = @_;
    $env->{RECUR} = 1;
    return (
        list([symbol('loop'), VECTOR->new([
            map evaluate($_, $env),
                @{$ast}[1..(@$ast-1)]])
        ]),
        $env,
    );
}

sub special_try {
    my ($ast, $env) = @_;
    my (undef, $body, $catch) = @$ast;
    local $@;
    my $val = eval { evaluate($body, $env) };
    return $val unless $@;
    my $err = $@;
    die ref($err) ? RT->printer->pr_str($err) : $err
        unless defined $catch;
    err "Invalid 'catch' clause" unless
        $catch and $catch->isa(LISTTYPE) and
        @$catch and $catch->[0]->isa(SYMBOL) and
        ${$catch->[0]} =~ /^catch\*?$/;
    my $e;
    (undef, $e, $ast) = @$catch;
    if (not ref($err)) {
        chomp $err;
        $err = string($err);
    }
    return (
        $ast,
        Lingy::Env->new(
            outer => $env,
            binds => [$e],
            exprs => [$err],
        ),
    );
}

sub special_throw {
    my ($ast, $env) = @_;
    require Carp;
    Carp::confess(
        evaluate($ast->[1], $env),
    );
}

sub special_var {
    my ($ast, $env) = @_;
    my (undef, $name) = @$ast;
    $env->get($name, 1)
        or err "Unable to resolve var: '$name' in this context";
    return VAR->new($name);
}

sub special_vector {
    my ($env, $vector, @args) = @_;
    err "Wrong number of args (${\ scalar @args}) passed to: " .
        "'lingy.lang.Vector'"
        unless @args == 1;
    evaluate(
        list([
            symbol('nth'),
            $vector,
            @args,
        ]),
        $env,
    );
}


# Helper functions:
sub is_class_symbol {
    my ($symbol) = @_;
    return unless ref($_[0]) eq SYMBOL;
    my $class = $$symbol;
    return unless $class =~ /\./;
    $class =~ s/^lingy\.lang\./Lingy::/;
    $class =~ s/\./::/g;
    (my $path = "$class.pm") =~ s/::/\//g;
    if (not exists $INC{$path}) {
        eval "require $class; 1" or
            err "Not a Lingy class: $class";
    }
    return $class;
}

sub macroexpand {
    my ($ast, $env) = @_;
    my ($sym, $call);
    # while ast is a macro call form
    while (
        ref($ast) eq LIST and
        $sym = $ast->[0] and
        ref($sym) eq SYMBOL
    ) {
        $sym = $$sym;
        if ($sym =~ /^\.(\S+)$/) {
            my ($member, $instance, @rest) = @$ast;
            $member = symbol(substr($$member, 1));
            return list([symbol('.'), $instance, $member, @rest]);
        }
        if ($sym =~ /^($namespace_re)\.$/) {
            my (undef, @args) = @$ast;
            # XXX Should expand to (new Foo.Bar 1 2 3)
            return list([
                symbol('.'),
                symbol($1),
                symbol('new'),
                @args,
            ]);
        }
        if ($sym =~ m{^($namespace_re)/($symbol_re)$}) {
            my $namespace = $1;
            my $sym_name = $2;
            (my $class = $namespace) =~ s/\./::/g;
            if ($class->can('new')) {
                my (undef, @args) = @$ast;
                return list([
                    symbol('.'),
                    symbol($namespace),
                    symbol($sym_name),
                    @args,
                ]);
            }
        }
        if (($call = $env->get($sym, 1)) and
            ref($call) eq MACRO
        ) {
            # expand macro call form
            $ast = evaluate($call->(@{$ast}[1..(@$ast-1)]));
        } else {
            last;
        }
    }
    return $ast;
}

sub quasiquote {
    my ($ast) = @_;
    return list([symbol('vec'), quasiquote_loop($ast)])
        if $ast->isa(VECTOR);
    return list([symbol('quote'), $ast])
        if $ast->isa(HASHMAP) or
            $ast->isa(SYMBOL);
    return $ast unless $ast->isa(LIST);
    my ($a0, $a1) = @$ast;
    return $a1
        if $a0 and
            $a0->isa(SYMBOL) and
            "$a0" eq 'unquote';
    return quasiquote_loop($ast);
}

sub quasiquote_loop {
    my ($ast) = @_;
    my $list = list([]);
    for my $elt (reverse @$ast) {
        if ($elt->isa(LISTTYPE) and
            $elt->[0] and
            $elt->[0]->isa(SYMBOL) and
            "$elt->[0]" eq 'splice-unquote'
        ) {
            $list = list([symbol('concat'), $elt->[1], $list]);
        } else {
            $list = list([symbol('cons'), quasiquote($elt), $list]);
        }
    }
    return $list;
}

1;

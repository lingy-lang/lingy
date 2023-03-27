use strict; use warnings;
package Lingy::Eval;

use Lingy::Common;

# Lingy Special Forms:
my $special_dispatch = {
    'def!'              => \&special_def,
    'defmacro!'         => \&special_defmacro,
    'do'                => \&special_do,
    '.'                 => \&special_dot,
    'fn*'               => \&special_fn,
    'if'                => \&special_if,
    'let*'              => \&special_let,
    'loop'              => \&special_loop,
    'recur'             => \&special_recur,
    'quasiquote'        => \&special_quasiquote,
    'quasiquoteexpand'  => \&special_quasiquoteexpand,
    'quote'             => \&special_quote,
    'try*'              => \&special_try,
    'var'               => \&special_var,
};


# Main eval functions:
our $ENV;
sub eval {
    my ($ast, $env) = @_;
    $ENV = $env;

    while (1) {
        $ast = macroexpand($ast, $env);

        return eval_ast($ast, $env) unless ref($ast) eq 'Lingy::Lang::List';

        return $ast unless @$ast;   # Empty list

        if (my $fn = $special_dispatch->{$ast->[0]}) {
            ($ast, $env) = $fn->($ast, $env);
            return $ast unless $env;

        } else {
            my ($fn, @args) = @{eval_ast($ast, $env)};
            return $fn->(@args) if ref($fn) eq 'CODE';
            $fn = $env->get($$fn) if ref($fn) eq 'Lingy::Lang::Var';
            ($ast, $env) = $fn->(@args);
        }
    }
}

sub eval_ast {
    my ($ast, $env) = @_;
    $ast->isa('Lingy::Base::List')
        ? ref($ast)->new([ map Lingy::Eval::eval($_, $env), @$ast ]) :
    $ast->isa('Lingy::Base::Map')
        ? ref($ast)->new([map Lingy::Eval::eval($_, $env), %$ast]) :
    $ast->isa('Lingy::Lang::Symbol')
        ? $env->get($$ast) :
    $ast;
}


# Special form handler functions:
sub special_def {
    my ($ast, $env) = @_;
    my (undef, $a1, $a2) = @$ast;
    err "Can't def a qualified symbol: '$a1'"
        if $a1 =~ m{./.};
    return $env->set($$a1, Lingy::Eval::eval($a2, $env));
}

sub special_defmacro {
    my ($ast, $env) = @_;
    my (undef, $a1, $a2) = @$ast;
    return $env->set($$a1, macro(Lingy::Eval::eval($a2, $env)));
}

sub special_do {
    my ($ast, $env) = @_;
    my (undef, @do) = @$ast;
    $ast = pop @do;
    eval_ast(list(\@do), $env);
    return ($ast, $env);
}

sub special_dot {
    my ($ast, $env) = @_;

    my (undef, $target, @args) = @$ast;
    if (@args == 1 and ref($args[0]) eq 'Lingy::Lang::List') {
        @args = @{$args[0]};
    }

    ($target, @args) = map {
        $_->isa('Lingy::Lang::List')
            ? Lingy::Eval::eval($_, $env) : $_;
    } ($target, @args);

    @args > 0 or err "Not enough args for . form";

    if (my $class = is_class_symbol($target)) {
        $target = "${class}::${shift @args}";
        @args = map { $_->isa('Lingy::Lang::Symbol')
            ? $env->get($_) : $_; } @args;
        no strict 'refs';
        return &{$target}(@args);
    }

    $target = $env->get($target)
        if $target->isa('Lingy::Lang::Symbol');

    if ($target->can('lingy_class')) {
        my $member = shift(@args);

        @args = map { $_->isa('Lingy::Lang::Symbol')
            ? $env->get($_) : $_; } @args;

        if (not $target->can($member)) {
            my $class = "$target"->lingy_class;
            err "No matching field found: '$member' " .
                "for class '$class'";
        }
        my $method = $$member;
        return $target->$method(@args);
    }

    XXX $ast, "Don't know how to '.' this yet";
}

sub special_fn {
    my ($ast, $env) = @_;
    return function($ast, $env);
}

sub special_if {
    my ($ast, $env) = @_;
    my (undef, $a1, $a2, $a3) = @$ast;
    $ast = ${boolean(Lingy::Eval::eval($a1, $env))} ? $a2 :
        defined $a3 ? $a3 : nil;
    return ($ast, $env);
}

sub special_let {
    my ($ast, $env) = @_;
    my (undef, $a1, $a2) = @$ast;
    err "First argument to 'let' must be a vector"
        unless ref($a1) eq 'Lingy::Lang::Vector';
    $env = Lingy::Env->new(outer => $env);
    for (my $i = 0; $i < @$a1; $i += 2) {
        $env->set(
            ${$a1->[$i]},
            Lingy::Eval::eval($a1->[$i+1], $env),
        );
    }
    $a2 = list([symbol('do'), @{$ast}[2..(@$ast-1)] ])
        if @$ast > 3;
    return ($a2, $env);
}

sub special_loop {
    my ($ast, $env) = @_;
    my (undef, $a1, $a2) = @$ast;
    if (not $env->{RECUR}) {
        err "First argument to 'loop' must be a vector"
            unless ref($a1) eq 'Lingy::Lang::Vector';
        $env = Lingy::Env->new(outer => $env);
        my $binds = [];
        for (my $i = 0; $i < @$a1; $i += 2) {
            push @$binds, ${$a1->[$i]};
            $env->set(
                ${$a1->[$i]},
                Lingy::Eval::eval($a1->[$i+1], $env),
            );
        }
        $a2 //= nil;
        $a2 = list([symbol('do'), @{$ast}[2..(@$ast-1)] ])
            if @$ast > 3;
        $env->{LOOP} = [$binds, $a2];
    } else {
        my $binds;
        ($binds, $a2) = @{$env->{LOOP}};
        if (@$a1 != @$binds) {
            err sprintf
                "Mismatched argument count to recur, " .
                "expected: %d args, got: %d",
                scalar(@$binds),
                scalar(@$a1);
        }
        my $i = 0;
        for my $bind (@$binds) {
            $env->set($bind, $a1->[$i++], $env);
        }
    }
    return ($a2, $env);
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
        list([symbol('loop'), vector([
            map Lingy::Eval::eval($_, $env),
                @{$ast}[1..(@$ast-1)]])
        ]),
        $env,
    );
}

sub special_try {
    my ($ast, $env) = @_;
    my (undef, $a1, $a2) = @$ast;
    local $@;
    my $val = eval { Lingy::Eval::eval($a1, $env) };
    return $val unless $@;
    my $err = $@;
    die ref($err) ? Lingy::Printer::pr_str($err) : $err
        unless defined $a2;
    err "Invalid 'catch' clause" unless
        $a2 and $a2->isa('Lingy::Base::List') and
        @$a2 and $a2->[0]->isa('Lingy::Lang::Symbol') and
        ${$a2->[0]} =~ /^catch\*?$/;
    my $e;
    (undef, $e, $ast) = @$a2;
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

sub special_var {
    my ($ast, $env) = @_;
    my (undef, $a1) = @$ast;
    $env->get($a1, 1)
        or err "Unable to resolve var: '$a1' in this context";
    return var($a1);
}


# Helper functions:
sub is_class_symbol {
    my ($symbol) = @_;
    return unless ref($_[0]) eq 'Lingy::Lang::Symbol';
    my $class = $$symbol;
    return unless $class =~ /\./;
    $class =~ s/^lingy\.lang\./Lingy.Lang./;
    $class =~ s/\./::/g;
    eval "require $class; 1" or
        err "Not a Lingy class: $class";
    return $class;
}

sub macroexpand {
    my ($ast, $env) = @_;
    my ($sym, $call);
    # while ast is a macro call form
    while (
        ref($ast) eq 'Lingy::Lang::List' and
        $sym = $ast->[0] and
        ref($sym) eq "Lingy::Lang::Symbol"
    ) {
        if ($$sym =~ /^\.(\S+)$/) {
            my ($member, $instance, @rest) = @$ast;
            $member = symbol(substr($$member, 1));
            return list([symbol('.'), $instance, $member, @rest]);
        }
        if (($call = $env->get($$sym, 1)) and
            ref($call) eq 'macro'
        ) {
            # expand macro call form
            $ast = Lingy::Eval::eval($call->(@{$ast}[1..(@$ast-1)]));
        } else {
            last;
        }
    }
    return $ast;
}

sub quasiquote {
    my ($ast) = @_;
    return list([symbol('vec'), quasiquote_loop($ast)])
        if $ast->isa('Lingy::Lang::Vector');
    return list([symbol('quote'), $ast])
        if $ast->isa('Lingy::Base::Map') or $ast->isa('Lingy::Lang::Symbol');
    return $ast unless $ast->isa('Lingy::Lang::List');
    my ($a0, $a1) = @$ast;
    return $a1 if $a0 and $a0->isa('Lingy::Lang::Symbol') and "$a0" eq 'unquote';
    return quasiquote_loop($ast);
}

sub quasiquote_loop {
    my ($ast) = @_;
    my $list = list([]);
    for my $elt (reverse @$ast) {
        if ($elt->isa('Lingy::Base::List') and
            $elt->[0] and
            $elt->[0]->isa('Lingy::Lang::Symbol') and
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

use strict; use warnings;
package Lingy::Eval;

use Lingy::Types;

sub eval {
    my ($ast, $env) = @_;

    while (1) {
        return eval_ast($ast, $env) unless $ast->isa('list');

        $ast = macroexpand($ast, $env);

        return eval_ast($ast, $env) unless $ast->isa('list');

        return $ast unless @$ast;

        my ($a0, $a1, $a2, $a3) = @$ast;
        my $sym = (ref($a0) eq 'symbol') ? $$a0 : '';

        if ('def!' eq $sym) {
            return $env->set($$a1, Lingy::Eval::eval($a2, $env));

        } elsif ('defmacro!' eq $sym) {
            return $env->set($$a1, macro(Lingy::Eval::eval($a2, $env)));

        } elsif ('ENV' eq $sym) {
            my $www = {};
            my $w = $www;
            my $e = $env;
            while ($e) {
                $w->{'+'} = join ' ', sort keys %{$e->{stash}};
                $w->{'^'} = {};
                $w = $w->{'^'};
                $e = $e->{outer};
            }
            WWW($www);
            $ast = nil;

        } elsif ('do' eq $sym) {
            my (undef, @do) = @$ast;
            $ast = pop @do;
            eval_ast(list(\@do), $env);

        } elsif ('fn*' eq $sym) {
            $a2 = list([symbol('do'), @{$ast}[2..(@$ast-1)] ])
                if @$ast > 3;
            return function($a1, $a2, $env);

        } elsif ('if' eq $sym) {
            $ast = ${boolean(Lingy::Eval::eval($a1, $env))} ? $a2 :
                defined $a3 ? $a3 : nil;

        } elsif ('let*' eq $sym) {
            $env = Lingy::Env->new(outer => $env);
            for (my $i = 0; $i < @$a1; $i += 2) {
                $env->set(${$a1->[$i]}, Lingy::Eval::eval($a1->[$i+1], $env));
            }
            $a2 = list([symbol('do'), @{$ast}[2..(@$ast-1)] ])
                if @$ast > 3;
            $ast = $a2;

        } elsif ('let*' eq $sym) {
            $env = Lingy::Env->new(outer => $env);
            for (my $i = 0; $i < @$a1; $i += 2) {
                $env->set(${$a1->[$i]}, Lingy::Eval::eval($a1->[$i+1], $env));
            }
            $ast = $a2;

        } elsif ('macroexpand' eq $sym) {
            return macroexpand($a1, $env);

        } elsif ('quasiquote' eq $sym) {
            $ast = quasiquote($a1);

        } elsif ('quasiquoteexpand' eq $sym) {
            return quasiquote($a1);

        } elsif ('quote' eq $sym) {
            return $a1;

        } elsif ('try*' eq $sym) {
            local $@;
            my $val = eval { Lingy::Eval::eval($a1, $env) };
            return $val unless $@;
            my $err = $@;
            die ref($err) ? Printer::pr_str($err) : $err
                unless defined $a2;
            die "Invalid 'catch' clause" unless
                $a2 and $a2->isa('Lingy::List') and
                @$a2 and $a2->[0]->isa('symbol') and
                ${$a2->[0]} =~ /^catch\*?$/;
            my $e;
            (undef, $e, $ast) = @$a2;
            if (not ref($err)) {
                chomp $err;
                $err = string($err);
            }
            $env = Lingy::Env->new(
                outer => $env,
                binds => [$e],
                exprs => [$err],
            );

        } else {
            my ($f, @args) = @{eval_ast($ast, $env)};
            return $f->(@args) if ref($f) eq 'CODE';
            ($ast, $env) = $f->(@args);
        }
    }
}

sub eval_ast {
    my ($ast, $env) = @_;
    $ast->isa('Lingy::List') ? ref($ast)->new([ map Lingy::Eval::eval($_, $env), @$ast ]) :
    $ast->isa('Lingy::Map') ? ref($ast)->new([map Lingy::Eval::eval($_, $env), %$ast]) :
    $ast->isa('symbol') ? $env->get($$ast) :
    $ast;
}

sub macroexpand {
    my ($ast, $env) = @_;
    while (is_macro_call($ast, $env)) {
        my ($name, @args) = @$ast;
        $ast = Lingy::Eval::eval($env->get($name)->(@args));
    }
    return $ast;
}

sub is_macro_call {
    my ($ast, $env) = @_;
    my $a0;
    (ref($ast) eq 'list' and
        ($a0) = @$ast and
        ref($a0) eq "symbol" and
        $env->find("$a0")
    ) ? ref($env->get("$a0")) eq 'macro' : 0;
}

sub quasiquote {
    my ($ast) = @_;
    return list([symbol('vec'), quasiquote_loop($ast)])
        if $ast->isa('vector');
    return list([symbol('quote'), $ast])
        if $ast->isa('Lingy::Map') or $ast->isa('symbol');
    return $ast unless $ast->isa('list');
    my ($a0, $a1) = @$ast;
    return $a1 if $a0 and $a0->isa('symbol') and "$a0" eq 'unquote';
    return quasiquote_loop($ast);
}

sub quasiquote_loop {
    my ($ast) = @_;
    my $list = list([]);
    for my $elt (reverse @$ast) {
        if ($elt->isa('Lingy::List') and
            $elt->[0] and
            $elt->[0]->isa('symbol') and
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

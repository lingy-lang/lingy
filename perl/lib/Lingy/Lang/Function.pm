package Lingy::Lang::Function;

use Lingy::Common();

use Lingy::Base;

use constant lingy_class => 'host.lang.Function';

*list = \&Lingy::Common::list;
*symbol = \&Lingy::Common::symbol;
sub err;
*err = \&Lingy::Common::err;

sub new {
    my ($class, $ast, $env) = @_;

    my (undef, @exprs) = @$ast;
    @exprs = (list([@exprs]))
        if ref($exprs[0]) eq 'Lingy::Lang::Vector';

    my $functions = [];
    my $variadic = '';

    for my $expr (@exprs) {
        err "fn expr is not a list"
            unless ref($expr) eq 'Lingy::Lang::List';
        my ($sig, @body) = @$expr;
        err "fn signature not a vector"
            unless ref($sig) eq 'Lingy::Lang::Vector';
        my $arity = (grep {$$_ eq '&'} @$sig) ? -1 : @$sig;
        if ($arity == -1) {
            $variadic = @$sig - 1;
        } elsif ($variadic) {
            err "Can't have fixed arity function " .
                "with more params than variadic function"
                if @$sig > $variadic;
        }
        @body = (list([ symbol('do'), @body ]))
            if @body > 1;
        if (exists $functions->[$arity+1]) {
            err $arity == -1
                ? "Can't have more than 1 variadic overload"
                : "Can't have 2 overloads with same arity";
        }
        $functions->[$arity+1] = [$sig, @body];
    }

    bless sub {
        my $arity = @_;
        my $function =
            $functions->[$arity+1] ? $functions->[$arity+1] :
            $arity >= (@$functions-1) ? $functions->[0] :
                err "Wrong number of args ($arity) passed to function";
        my ($sig, $ast) = @$function;

        return (
            $ast,
            Lingy::Env->new(
                outer => $env,
                binds => $sig,
                exprs => \@_,
            ),
        );
    }, $class;
}

sub clone {
    my ($fn) = @_;
    bless sub { goto &$fn }, ref($fn);
}

1;

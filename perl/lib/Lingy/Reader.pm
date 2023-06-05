use strict; use warnings;
package Lingy::Reader;

use Lingy::Common;

my $tokenize_re = qr/
    (?:                     # Ignore:
        \#\!.* |                # hashbang line
        [\s,] |                 # whitespace, commas,
        ;.*                     # comments
    )*
    (                       # Capture all these tokens:
        \#\( |                  # Lambda
        ~@ |                    # Unquote-splice token
        [\[\]{}()'`~^@] |       # Single character tokens
        \#?                     # Possibly a regex
        "(?:                    # Quoted string
            \\. |                   # Escaped char
            [^\\"]                  # Any other char
        )*"? |                      # Match if missing ending quote
                                # Other tokens
        [^\s\[\]\{\}\(\)\'\"\`\,\;]*
    )
/xo;

sub new {
    my $class = shift;
    bless {
        tokens => [],
        lambda => [],
        @_,
    }, $class;
}

sub tokenize {
    [
        grep length,
        $_[0] =~ /$tokenize_re/g
    ];
}

sub read_str {
    my ($self, $str, $repl) = @_;
    local $self->{repl} = $repl;
    my $tokens = $self->{tokens} = tokenize($str);
    my @forms;
    while (@$tokens) {
        my $form = $self->read_form;
        if (defined $form) {
            push @forms, $form;
        }
    }
    return @forms;
}

sub read_form {
    my ($self) = @_;
    local $_ = $self->{tokens}[0];
    /^\($/ ? $self->read_list(LIST, ')') :
    /^\[$/ ? $self->read_list(VECTOR, ']') :
    /^\{$/ ? $self->read_hash_map(HASHMAP, '}') :
    /^'$/ ? $self->read_quote('quote') :
    /^`$/ ? $self->read_quote('quasiquote') :
    /^~$/ ? $self->read_quote('unquote') :
    /^~\@$/ ? $self->read_quote('splice-unquote') :
    /^\@$/ ? $self->read_quote('deref') :
    /^\^$/ ? $self->with_meta :
    /^#\(/ ? $self->read_lambda :
    /^%\d*$/ ? $self->read_lambda_symbol :
    $self->read_scalar;
}

sub read_more {
    my ($self) = @_;
    if ($self->{repl}) {
        my $line = Lingy::ReadLine::readline(1);
        if (defined $line) {
            push @{$self->{tokens}}, @{tokenize($line)};
            return 1;
        }
    }
    return;
}

sub read_list {
    my ($self, $type, $end) = @_;
    my $tokens = $self->{tokens};
    shift @$tokens;
    my $list = $type->new([]);
    while (1) {
        while (@$tokens) {
            if ($tokens->[0] eq $end) {
                shift @$tokens;
                return $list;
            }
            push @$list, $self->read_form;
        }
        $self->read_more and next;
        err "Reached end of input in 'read_list'";
    }
}

sub read_lambda {
    my ($self) = @_;
    my $tokens = $self->{tokens};
    shift @$tokens;
    push @{$self->{lambda}}, {
        sym => {},
        max => 0,
    };
    my $list = [];
    outer: while (1) {
        while (@$tokens) {
            if ($tokens->[0] eq ')') {
                shift @$tokens;
                last outer;
            }
            push @$list, $self->read_form;
        }
        $self->read_more and next;
        err "Reached end of input in 'read_list'";
    }
    my $lambda = pop @{$self->{lambda}};
    my ($sym, $max) = @{$lambda}{'sym', 'max'};
    my $syms = [];
    for (my $i = 1; $i <= $lambda->{max}; $i++) {
        push @$syms, $sym->{"%$i"} // symbol("p${i}_${\RT->nextID}");
    }

    LIST->new([
        SYMBOL->new('fn*'),
        VECTOR->new($syms),
        LIST->new($list),
    ]);
}

sub read_lambda_symbol {
    my ($self) = @_;
    my $token = shift @{$self->{tokens}};
    return symbol($token) unless @{$self->{lambda}};
    $token = '%1' if $token eq '%';
    my $num = substr($token, 1);
    my $lambda = $self->{lambda}->[-1];
    $lambda->{max} = $num if $num > $lambda->{max};
    $lambda->{sym}{$token} //= symbol("p${num}_${\RT->nextID}");
}

sub read_hash_map {
    my ($self, $type, $end) = @_;
    my $tokens = $self->{tokens};
    shift @$tokens;
    my $hash = $type->new([]);
    my $i = 0;
    my $key;
    while (1) {
        while (@$tokens > 0) {
            if ($tokens->[0] eq $end) {
                shift @$tokens;
                err "Map literal must contain an even number of forms"
                    if defined $key;
                return $hash;
            }
            $i++;
            if ($i % 2) {
                $key = $self->read_form;
            } else {
                my $key_str = $type->_get_key($key);
                err "Duplicate key: '$key'"
                    if exists $hash->{$key_str};
                my $val= $self->read_form;
                $hash->{$key_str} = $val;
                undef $key;
            }
        }
        $self->read_more and next;
        err "Reached end of input in 'read_hash_map'";
    }
}

my $string_re = qr/#?"((?:\\.|[^\\"])*)"/;
my $string_unescape = {
    'n' => "\n",
    't' => "\t",
    '"' => '"',
    '\\' => "\\",
};
my $regexp_unescape = {
    'A' => "\\A",
    'b' => "\\b",
    'd' => "\\d",
    'n' => "\\n",
    'r' => "\\r",
    's' => "\\s",
    't' => "\\t",
    'w' => "\\w",
    'z' => "\\z",
    '"' => '\\"',
    '\\' => "\\\\",
};
sub read_scalar {
    my ($self) = @_;
    my $scalar = local $_ = shift @{$self->{tokens}};

    while (/^(#?)"/) {
        my $is_regex = $1;
        if (/^$string_re$/) {
            s/^$string_re$/$1/;
            if ($is_regex) {
                s/\\(.)/
                    $regexp_unescape->{$1}
                        or err("Unsupported escape character '\\$1'")
                /ge;
            } else {
                s/\\(.)/
                    $string_unescape->{$1}
                        or err("Unsupported escape character '\\$1'")
                /ge;
            }
            return $is_regex ? REGEX->new($_) : STRING->new($_);
        }
        if ($self->{repl}) {
            my $line = Lingy::ReadLine::readline(1);
            if (defined $line) {
                $_ .= "\n$line";
                next;
            }
        }
        err "Reached end of input looking for '\"'";
    }
    return nil if $_ eq 'nil';
    return true if $_ eq 'true';
    return false if $_ eq 'false';
    return KEYWORD->new($_) if /^:/;
    return NUMBER->new($_) if /^-?\d+$/;
    return CHARACTER->read($_) if /^\\/;
    err "Unmatched delimiter: '$_'" if /^[\)\]\}]$/;
    return $self->read_symbol($_);
}

# Defined separately to allow subclassing:
sub read_symbol {
    my ($self, $symbol) = @_;
    if (my $ids = $self->{autogensym}) {
        if ($symbol =~ m{^([^/]+)#$}) {
            my $id = $ids->{$1} //= RT->nextID();
            $symbol =~ s/#$/__${id}__auto__/;
        }
    }
    symbol($symbol);
}

sub read_quote {
    my ($self, $quote) = @_;
    shift @{$self->{tokens}};
    my $form;
    if ($quote eq 'quasiquote') {
        $self->{autogensym} = {};
        $form = $self->read_form;
        delete $self->{autogensym};
    } else {
        $form = $self->read_form;
    }
    return list([symbol($quote), $form]);
}

sub with_meta {
    my ($self, $quote) = @_;
    shift @{$self->{tokens}};

    my $meta = $self->read_form;
    my $form = $self->read_form;

    bless [
        symbol('with-meta'),
        $form,
        $meta,
    ], LIST;
}

1;

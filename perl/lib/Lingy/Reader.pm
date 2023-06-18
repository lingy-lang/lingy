use strict; use warnings;
package Lingy::Reader;

use Lingy::Common;

our $feature_keyword = ':lingy.pl';

my $tokenize_re = qr/
    (?:                     # Ignore:
        \#\!.* |                # hashbang line
        [\s,] |                 # whitespace, commas,
        ;.*                     # comments
    )*
    (                       # Capture all these tokens:
        \#\_ |                  # Ignore next form
        \#\' |                  # Var
        \#\( |                  # Lambda
        \#\{ |                  # HashSet
        \#\? |                  # Reader conditional
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
        ignore => 0,
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
    my $tokens = $self->{tokens};
    while (not @$tokens) { $self->read_more }
    local $_ = $tokens->[0];
    /^\($/ ? $self->read_list(LIST, ')') :
    /^\[$/ ? $self->read_list(VECTOR, ']') :
    /^\{$/ ? $self->read_hash('map') :
    /^\#\{$/ ? $self->read_hash('set') :
    /^'$/ ? $self->read_quote('quote') :
    /^`$/ ? $self->read_quote('quasiquote') :
    /^~$/ ? $self->read_quote('unquote') :
    /^~\@$/ ? $self->read_quote('splice-unquote') :
    /^\@$/ ? $self->read_quote('deref') :
    /^\^$/ ? $self->with_meta :
    /^#\'$/ ? $self->read_var :
    /^#\($/ ? $self->read_lambda :
    /^#_$/ ? $self->read_ignore :
    /^#\?$/ ? $self->read_cond :
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

sub read_var {
    my ($self) = @_;
    shift @{$self->{tokens}};
    my $var = shift @{$self->{tokens}};
    if ($var !~ m</>) {
        $var = RT->current_ns_name . "/$var";
    }
    VAR->new($var);
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

sub read_hash {
    my ($self, $type) = @_;
    my $tokens = $self->{tokens};
    shift @$tokens;
    my $hash = [];
    while (1) {
        while (@$tokens > 0) {
            if ($tokens->[0] eq '}') {
                shift @$tokens;
                my $method = "make_hash_$type";
                return $self->$method($hash);
            }
            push @$hash, $self->read_form;
        }
        $self->read_more and next;
        err "Reached end of input in 'read_hash'";
    }
}

sub make_hash_map {
    my ($self, $data) = @_;
    err "Map literal must contain an even number of forms"
        if @$data % 2 and not $self->{ignore};
    my %hash;
    for (my $i = 0; $i < @$data; $i += 2) {
        err "Duplicate key: '$data->[$i]'"
            if $hash{$data->[$i]}++ and
                not $self->{ignore};
    }
    HASHMAP->new($data);
}

sub make_hash_set {
    my ($self, $data) = @_;
    my %hash;
    my $set = [];
    for my $elem (@$data) {
        err "Duplicate key: '$elem'"
            if $hash{$elem}++ and
                not $self->{ignore};
        push @$set, $elem, $elem;
    }
    HASHSET->new($data);
}

sub read_hash_set {
    my ($self) = @_;
    my $tokens = $self->{tokens};
    shift @$tokens;
    my $hash = HASHSET->new([]);
    my $i = 0;
    while (1) {
        while (@$tokens > 0) {
            if ($tokens->[0] eq '}') {
                shift @$tokens;
                return $hash;
            }
            $i++;
            my $val = $self->read_form;
            my $key = HASHSET->_get_key($val);
            err "Duplicate key: '$val'"
                if exists $hash->{$key} and
                    not $self->{ignore};
            $hash->{$key} = $val;
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
    '.' => '\\.',
    '\\' => "\\\\",
    '[' => "\\[",
    ']' => "\\]",
    '{' => "\\{",
    '}' => "\\}",
    '(' => "\\(",
    ')' => "\\)",
    '+' => "\\+",
    '*' => "\\*",
    '?' => "\\?",
    '^' => "\\^",
    '$' => "\\\$",
    '|' => "\\|",
};
sub read_scalar {
    my ($self) = @_;
    my $scalar = local $_ = shift @{$self->{tokens}};

    while (/^(#?)"/) {
        my $is_regex = $1;
        if (/^$string_re$/) {
            s/^$string_re$/$1/;
            if (not $self->{ignore}) {
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
    return NUMBER->new($_) if /^-?\d+(?:\.\d+)?$/;
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
    my ($self) = @_;

    my $tokens = $self->{tokens};
    my @meta;

    while (@$tokens > 2 and $tokens->[0] eq '^') {
        shift @$tokens;
        my $meta = $self->read_form;
        my $type = ref($meta);
        if ($type eq SYMBOL or $type eq STRING) {
            unshift @meta, KEYWORD->new(':tag'), $meta;
        } elsif ($type eq KEYWORD) {
            unshift @meta, $meta, true;
        } elsif ($type eq HASHMAP) {
            unshift @meta, %$meta;
        } else {
            err "Metadata must be Symbol,Keyword,String or Map"
        }
    }

    my $meta = $self->make_hash_map(\@meta);

    my $form = $self->read_form;

    RT->meta->{"$form"} = $meta;

    return $form;
}

sub read_ignore {
    my ($self) = @_;
    $self->{ignore}++;
    my $tokens = $self->{tokens};
    shift @$tokens;
    while (not defined $self->read_form) {}
    $self->{ignore}--;
    return;
}

sub read_cond {
    my ($self) = @_;
    my $tokens = $self->{tokens};
    shift @$tokens;
    err "read-cond body must be a list"
        unless @$tokens and $tokens->[0] eq '(';
    my $list = $self->read_form;
    err "read-cond requires an even number of forms"
        if @$list % 2;
    while (@$list) {
        my ($keyword, $form) = splice(@$list, 0, 2);
        err "Feature should be a keyword: $keyword"
            unless $keyword->isa(KEYWORD);
        if ("$keyword" eq $feature_keyword or
            "$keyword" eq ':default'
        ) {
            return $form;
        }
    }
    return;
}

1;

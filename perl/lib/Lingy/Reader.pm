use strict; use warnings;
package Lingy::Reader;

use Lingy::Common;

sub new {
    my $class = shift;
    bless {
        tokens => [],
        @_,
    }, $class;
}

sub tokenize {
    [
        grep length,
        $_[0] =~ /
            (?:                     # Ignore:
                [\s,] |                 # whitespace, commas,
                ;.*                     # comments
            )*
            (                       # Capture all these tokens:
                ~@ |                    # Unquote-splice token
                [\[\]{}()'`~^@] |       # Single character tokens
                "(?:                    # Quoted string
                    \\. |                   # Escaped char
                    [^\\"]                  # Any other char
                )*"? |                      # Match if missing ending quote
                                        # Other tokens
                [^\s\[\]\{\}\(\)\'\"\`\,\;]*
            )
        /xog
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
    /^\($/ ? $self->read_list('Lingy::Lang::List', ')') :
    /^\[$/ ? $self->read_list('Lingy::Lang::Vector', ']') :
    /^\{$/ ? $self->read_hash_map('Lingy::Lang::HashMap', '}') :
    /^'$/ ? $self->read_quote('quote') :
    /^`$/ ? $self->read_quote('quasiquote') :
    /^~$/ ? $self->read_quote('unquote') :
    /^~\@$/ ? $self->read_quote('splice-unquote') :
    /^\@$/ ? $self->read_quote('deref') :
    /^\^$/ ? $self->with_meta :
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
        while (@$tokens > 0) {
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

sub read_hash_map {
    my ($self, $type, $end) = @_;
    my $tokens = $self->{tokens};
    shift @$tokens;
    my $pairs = [];
    while (1) {
        while (@$tokens > 0) {
            if ($tokens->[0] eq $end) {
                shift @$tokens;
                err "Map literal must contain an even number of forms"
                    if @$pairs % 2;
                return $type->new($pairs);
            }
            push @$pairs, $self->read_form;
        }
        $self->read_more and next;
        err "Reached end of input in 'read_hash_map'";
    }
}

my $string_re = qr/"((?:\\.|[^\\"])*)"/;
my $unescape = {
    'n' => "\n",
    't' => "\t",
    '"' => '"',
    '\\' => "\\",
};
sub read_scalar {
    my ($self) = @_;
    my $scalar = local $_ = shift @{$self->{tokens}};

    while (/^"/) {
        if (s/^$string_re$/$1/) {
            s/\\([nt\"\\])/$unescape->{$1}/ge;
            return string($_);
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
    return true if $_ eq 'true';
    return false if $_ eq 'false';
    return nil if $_ eq 'nil';
    return number($_) if /^-?\d+$/;
    return keyword($_) if /^:/;
    return char($_) if /^\\/;
    err "Unmatched delimiter: '$_'" if /^[\)\]\}]$/;
    return $self->read_symbol($_);
}

# Defined separately to allow subclassing:
sub read_symbol {
    my ($self, $symbol) = @_;
    if (my $ids = $self->{autogensym}) {
        if ($symbol =~ m{^([^/]+)#$}) {
            my $id = $ids->{$1} //= Lingy::Lang::RT::nextID();
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
    ], 'Lingy::Lang::List';
}

1;

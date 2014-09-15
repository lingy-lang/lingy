package Lingy::Command;
use Lingy::Base;

has in => ();
has out => ();
has from => ();
has to => ();

use Getopt::Long;

my $extension_map = {
    pl => 'perl5',
    pm => 'perl5',
    pm5 => 'perl5',
    p6 => 'perl6',
    pl6 => 'perl6',
    pm6 => 'perl6',
    yml => 'yaml',
    yaml => 'yaml',
};

my $language_map = { map {($_, 1)} values %$extension_map };

my $compiler_map = {
    yaml => 'Lingy::Compiler::YAML',
    perl5 => 'Lingy::Compiler::Perl5',
};

my $emitter_map = {
    perl5 => 'Lingy::Emitter::Perl5',
    perl6 => 'Lingy::Emitter::Perl6',
    yaml => 'Lingy::Emitter::YAML',
};

sub run {
    my ($self) = @_;

    local @ARGV = @{$self->{args}};
    GetOptions(
        'to=s' => \$self->{to},
        'from=s' => \$self->{from},
        'in=s' => \$self->{in},
        'out=s' => \$self->{out},
    );

    if (@ARGV and not $self->{in}) {
        $self->{in} = shift @ARGV;
    }
    die "Unknown arguments '@ARGV'"
        if @ARGV;

    if ($self->{in} and not $self->{from} and $self->{in} =~ /\.(\w+)$/) {
        $self->{from} = $1;
    }
    if ($self->{out} and not $self->{to} and $self->{out} =~ /\.(\w+)$/) {
        $self->{to} = $1;
    }

    die "--from option required"
        unless $self->{from};
    die "--to option required"
        unless $self->{to};
    die "Unknown 'from' value '$self->{from}'"
        unless exists $extension_map->{$self->{from}};
    die "Unknown 'to' value '$self->{to}'"
        unless exists $extension_map->{$self->{to}};

    my $input = $self->get_input;
    my $compiler = $self->get_compiler;
    my $emitter = $self->get_emitter;
    my $ast = $compiler->compile($input);
    my $output = $emitter->emit($ast);
    $self->write_output($output);
}

sub get_input {
    my ($self) = @_;
    local $/;
    if (my $in = $self->{in}) {
        open my $fh, $in
            or die "Can't open '$in' for input";
        return <$fh>;
    }
    else {
        return <>;
    }
}

sub write_output {
    my ($self, $output) = @_;
    if (my $out = $self->{out}) {
        open my $fh, $out
            or die "Can't open '$out' for output";
        print $fh $output;
    }
    else {
        print $output;
    }
}

sub get_compiler {
    my ($self) = @_;
    my $from = $self->{from} or die;
    my $lang = $extension_map->{$from} || $from;
    my $class = $compiler_map->{$lang}
        or die "Invalid Lingy compiler language: '$lang'";
    eval "require $class; 1"
        or die "$@";
    $class->new;
}

sub get_emitter {
    my ($self) = @_;
    my $to = $self->{to} or die;
    my $lang = $extension_map->{$to} || $to;
    my $class = $emitter_map->{$lang}
        or die "Invalid Lingy emitter language: '$lang'";
    eval "require $class; 1"
        or die "$@";
    $class->new;
}



1;

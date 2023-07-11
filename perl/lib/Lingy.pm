use strict; use warnings;
package Lingy;
our $VERSION = '0.1.18';

my $rt = 0;

use constant error_prefix => 'Lingy Error:';

sub new {
    die "Lingy->new() takes no arguments"
        unless @_ == 1;
    my ($class) = @_;
    require Lingy::RT;
    my $rt_class = "${class}::RT";
    $rt_class->init unless $Lingy::RT::OK;
    return bless {
        RT => $rt_class,
    }, $class;
}

sub rep {
    die "Lingy->rep(string) takes one argument"
        unless @_ == 2;
    my ($self, $string) = @_;
    local $Lingy::Common::error_prefix = $self->error_prefix;
    my ($ret) = $self->{RT}->rep($string);
    return $ret;
}

sub read {
    die "Lingy->read(string) takes one argument"
        unless @_ == 2;
    my ($self, $string) = @_;
    local $Lingy::Common::error_prefix = $self->error_prefix;
    my (@ret) = $self->{RT}->reader->read_str($string);
    return wantarray ? @ret : $ret[0];
}

sub eval {
    die "Lingy->eval(form) takes one argument"
        unless @_ == 2;
    my ($self, $form) = @_;
    local $Lingy::Common::error_prefix = $self->error_prefix;
    $self->{RT}->eval($form);
}

sub print {
    die "Lingy->print(form) takes one argument"
        unless @_ == 2;
    my ($self, $form) = @_;
    local $Lingy::Common::error_prefix = $self->error_prefix;
    $self->{RT}->printer->pr_str($form);
}

1;

use strict; use warnings;
package Lingy::Exception;

use overload '""' => sub {
    $_[0]->{msg};
};

sub new {
    my ($class, $msg, $data) = @_;
    my $self = bless { msg => $msg }, $class;
    $self->{data} = $data if $data;
    return $self;
}

1;

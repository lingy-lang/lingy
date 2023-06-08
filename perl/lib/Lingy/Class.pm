# This module is a base class for all Lingy object classes and base classes,
# and also a class for 'Lingy::Class' objects.

use strict; use warnings;
package Lingy::Class;

# This section is base class support for all Lingy object classes.
# They all inherit from this:

sub new {
    die sprintf "No 'new' method defined for class '%s'.", ref($_[0]);
}

sub NAME {
    my ($self) = @_;
    my $class = ref($self) or die;
    $class =~ s/^Lingy::/lingy.lang./;
    return $class;
}

my %common = map {($_, 1)} @Lingy::Common::EXPORT;

sub _method_names {
    my ($self) = @_;
    my $class = ref($self) || $self;
    no strict 'refs';
    grep {
        not(
            exists($common{$_}) or
            /(^_|^[A-Z]+$|can|import|isa|new)/
        )
    } keys %{"$class\::"};
}


# This section is for special Lingy::Class objects, which are needed to
# mimic Clojure class behavior.

use overload '""' => sub {
    ref($_[0]) eq __PACKAGE__ ? ${$_[0]} : $_[0];
};

sub _new {
    my (undef, $name) = @_;
    bless \$name, __PACKAGE__;
}

sub _name {
    ref($_[0]) eq __PACKAGE__ or
        die sprintf "Can't call '_name' on '%s' object",
            ref($_[0]);
    my $name = ${$_[0]};
    $name =~ s/^Lingy::/lingy.lang./;
    return $name;
}

# Public methods:
sub isInstance {
    my ($base_class, $instance) = @_;
    my $instance_class = ref($instance);
    $instance->isa($base_class) ? Lingy::Common::true() : Lingy::Common::false();
}

1;

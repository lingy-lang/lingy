package Lingy::Compiler;
use Lingy::Base;

has input => ();
has ast => sub { Lingy::AST->new };

use Lingy::AST;

sub compile {
    die "compile() method not implemented";
}

1;

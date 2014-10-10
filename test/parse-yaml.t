my $t = -e 't' ? 't' : 'test';

use Test::More;

# use Lingy::Compiler::YAML;
# use XXX with => 'YAML::XS';
# 
# my $compiler = Lingy::Compiler::YAML->new(file => "$t/PigLatin.lingy.yaml");
# 
# my $ast = $compiler->compile;
# 
# is $ast->{module}{name}, 'Pig.Latin';
# 
# XXX $ast;

pass;

done_testing;

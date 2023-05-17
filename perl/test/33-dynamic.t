use Lingy::Test;

test '*lingy-version*',
     '{:major 0, :minor 1, :incremental 0, :qualifier nil}';
test '*clojure-version*',
     '{:major 1, :minor 11, :incremental 1, :qualifier nil}';

test '(lingy-version)',
     '"0.1.0"';
test '(clojure-version)',
     '"1.11.1"';

test '*HOST*',
     '"perl"';

test '*file*',
     '"NO_SOURCE_PATH"';

test '*ARGV*',
     'nil';

test '*command-line-args*',
     'nil';

test '*ns*',
     '#<Namespace user>';

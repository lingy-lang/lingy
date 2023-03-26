use Lingy::Test;

test '(fn ())',
    "fn signature not a vector";
test '(fn ([& a]) ([& b]))',
    "Can't have more than 1 variadic overload";
test '(fn ([x]) ([y]))',
    "Can't have 2 overloads with same arity";
test '(fn ([& x]) ([y z]))',
    "Can't have fixed arity function with more params than variadic function";

done_testing;

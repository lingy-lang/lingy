use Lingy::Test;

tests <<'...';
- - (fn ())
  - fn signature not a vector
- - (fn ([& a]) ([& b]))
  - Can't have more than 1 variadic overload
- - (fn ([x]) ([y]))
  - Can't have 2 overloads with same arity
- - (fn ([& x]) ([y z]))
  - Can't have fixed arity function with more params than variadic function
...

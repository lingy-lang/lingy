use Lingy::Test;

note "Testing (list* ...)";
test q<(list* ())>,
     q<nil>;
test q<(list* 5 ())>,
     q<(5)>;
test q<(list* 5 6 ())>,
     q<(5 6)>;
test q<(list* 5 6 '(2 3))>,
     q<(5 6 2 3)>;

note "Testing classes";
test q<lingy.lang.String>,
     q<lingy.lang.String>;
test q<String>,
     q<lingy.lang.String>;

test q<(type 42)>,
     q<lingy.lang.Number>;
test q<(type (type 42))>,
     q<lingy.lang.Class>;
test q<(type Number)>,
     q<lingy.lang.Class>;

done_testing;

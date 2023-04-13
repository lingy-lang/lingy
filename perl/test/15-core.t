use Lingy::Test;

# list*
test q<(list* ())>,
     q<nil>;
test q<(list* 5 ())>,
     q<(5)>;
test q<(list* 5 6 ())>,
     q<(5 6)>;
test q<(list* 5 6 '(2 3))>,
     q<(5 6 2 3)>;

done_testing;

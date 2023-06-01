use Lingy::Test;

tests <<"...";
- - (instance? lingy.lang.Number 42)
  - 'true'
- - (instance? Number 42)
  - 'true'
- - (instance? Number true)
  - 'false'
- - (instance? Boolean true)
  - 'true'
- - (boolean? false)
  - 'true'
- - (boolean? 42)
  - 'false'
- - (boolean? "false")
  - 'false'

- - (boolean nil)
  - 'false'
- - (boolean false)
  - 'false'
- - (boolean "")
  - 'true'
- - (boolean true)
  - 'true'
- - (boolean? (boolean false))
  - 'true'

- - (atom 42)
  - (atom 42)
- - (instance? Atom (atom 42))
  - 'true'
- - (instance? Atom 42)
  - 'false'

- - (class? Boolean)
  - 'true'
- - (class? lingy.lang.String)
  - 'true'
# TODO Need to test more class? things
# - - (class? lingy.lang.Namespace)
# - - (class? 'lingy.lang.Namespace)

- - (false? nil)
  - 'false'
- - (false? false)
  - 'true'
...

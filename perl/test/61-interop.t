use Lingy::Test;

tests <<"...";
- - 42
  - 42
...

__DATA__


# Perl and Lingy Modules

Modules (files) used by Lingy can be:

- A Lingy source file (.ly)
  - (require 'Foo.Bar)
  - (refer 'Foo.Bar)

- A Lingy Namespace Perl module
  - Inherits from Lingy::Namespace
  - Can currently also have a sibling .ly file

- A Class Perl module
  - ->can('new') determines if module is a class
  - (import Foo.Bar)    # Returns a Foo.Bar class
  - (Foo.Bar. :x 1 :y 2)  # new

- A Functional (non-OO) Perl module
  - Has no ->can('new')
  - (import Foo.Bar)    # Returns nil


# Macro Expansions


- If a fully qualified symbol if used as a function and the namespace part is a
  class
  - (macroexpand '(Long/toString 123))  ->  (. Long toString 123)
- If namespace part is not a class is doesn't expand
  - (macroexpand '(Wrong/toString 123))  ->  (Wrong/toString 123)
- Therefore at runtime we can consider Xyz/fn1 to be a function call in the Xyz
  Perl module if 'Xyz' is not a namespace but is a loaded module
- We need to keep a table of such modules

- Object instantiation
  - (Foo.Bar. :x 1 :y 2)  ->  (new Foo.Bar :x 1 :y 2)
- Method calls
  - (.foo xyz 4 5)  ->  (. xyz foo 4 5)
- Chained method calls
  - (.. Float (sum 4 5) toString toUpperCase)  ->
    (. (. (. Float (sum 4 5)) toString) toUpperCase)
- Multiple calls on same object
  - (macroexpand '(doto (java.util.Stack.) (.push 1) (.push 2)))  ->
    (let* [G__2676 (java.util.Stack.)] (.push G__2676 1) (.push G__2676 2) G__2676)

- Instance Accessors get and set
- (.x pt)               # get
- (set! (.x pt) 10)     # set
- In perl we can probabley use a method call for set
  (.x pt 10)
- Also:
  - (.-instanceField instance)  ->  (. instance -instanceField)
  - Use - (or maybe : ) as prefix for instance fields
- See https://clojure.org/reference/java_interop#_the_dot_special_form

- These both produce 3.141592653589793
  - Math/PI
  - (Math/PI)
    - Expands to: (. Math PI)

# Core Functions for Namespaces and Classes

- new
- instance?

- class             Returns the Class of x
- class?            Returns true if x is an instance of Class
- gen-class         Generate a Perl "class"

- *ns*
- all-ns
- create-ns
- find-ns
- in-ns
- ns
- ns-aliases
- ns-imports
- ns-interns
- ns-map
- ns-name
- ns-publics
- ns-refers
- ns-resolve
- ns-unalias
- ns-unmap
- remove-ns
- the-ns



# Imports
- lingy.lang.* classes ar automatically imported

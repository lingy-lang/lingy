Lingy
=====

A Modern Acmeist Lisp Dialect


# Synopsis

Run the Lingy REPL:

```
$ lingy
Welcome to Lingy [perl]

user> (prn "Hello, world!")
"Hello, world!"
nil
user>
```

or a Lingy one-liner:

```
$ lingy -e '(println "Hello, world!")'
Hello, world!
```

or run a Lingy program file:

```
$ echo '(println "Hello, world!")' > hello.ly
$ lingy hello.ly
Hello, world!
```

or run an example Lingy program:

```
$ curl -sL https://raw.githubusercontent.com/ingydotnet/lingy/main/eg/99-bottles.ly | lingy - 3
3 bottles of beer on the wall
3 bottles of beer
Take one down, pass it around
2 bottles of beer on the wall.

2 bottles of beer on the wall
2 bottles of beer
Take one down, pass it around
1 bottles of beer on the wall.

1 bottles of beer on the wall
1 bottles of beer
Take one down, pass it around
0 bottles of beer on the wall.
```


# Description

Lingy is a Lisp dialect written in many languages, including: Perl.

Clojure is a Lisp dialect that compiles to run on the JVM.

ClojureScript uses the same Clojure source code but compiles to NodeJS.

Lingy is the runtime that supports the YAMLScript language.

YAMLScript is meant to be implemented in all the same languages as Lingy.

Lingy is heavily influenced by the Clojure (Lisp) language.
It aspires to be largely interoperable with Clojure.
Currently it supports just a tiny subset of Clojure but supports Lisp basics
like function application and macros.

Lingy started as a Perl [implementation](
https://github.com/ingydotnet/mal/tree/perl.2/impls/perl.2) of the
[Make a Lisp](https://github.com/kanaka/mal) project.
This provided a bare-bones Clojure-inspired Lisp interpreter.


# `lingy` CLI Usage

The Lingy language installs a command `lingy`.
You can use this command to run Lingy programs, start a Lingy REPL or run
Lingy one-liner expressions.

* `lingy --repl` (or just `lingy`)

  Starts a Lingy interactive REPL.
  The REPL has readline support that includes:

  * Command history
  * CTL-R searching
  * Parentheses match highlighting
  * CTL-C to abort a command w/o leaving REPL

  Use CTL-D to exit the REPL

* `lingy program.ly foo bar`

  Run a Lingy program passing in arguments.
  Arguments are available in Lingy as `*ARGV*`.

* `cat program.ly | lingy - foo bar`

  Run a Lingy program from STDIN and pass in arguments.
  The `-` means run from STDIN instead of a file.
  If there are no arguments you can omit the `-`.

* `lingy -e '(println "Hello" (nth *ARGV* 0))' world`

  Run a Lingy one-liner with arguments.

  When used with `--repl`, run the `-e` code first, then enter the REPL.


## `lingy` CLI Options

* `-e <string>`, `--eval=<string>`

  A Lingy string to evaluate.

* `-r`, `--repl`

  Start a Lingy REPL.
  Can be used with `-e`.

* `--ppp`

  Print the Lingy compiled AST for a `-e` expression.

* `--xxx`

  YAML dump the Lingy compiled AST for a `-e` expression.


# Supported Functions

* `*`
* `+`
* `-`
* `/`
* `<`
* `<=`
* `=`
* `==`
* `>`
* `>=`
* `apply`
* `*ARGV*`
* `assoc`
* `atom`
* `atom?`
* `catch`
* `concat`
* `cond`
* `conj`
* `cons`
* `contains?`
* `count`
* `dec`
* `def`
* `defmacro`
* `deref`
* `dissoc`
* `do`
* `empty?`
* `eval`
* `false`
* `false?`
* `*file*`
* `first`
* `fn`
* `fn?`
* `get`
* `getenv`
* `hash-map`
* `*host-language*`
* `if`
* `join`
* `keys`
* `keyword`
* `keyword?`
* `let`
* `list`
* `list?`
* `load-file`
* `macro?`
* `macroexpand`
* `map`
* `map?`
* `meta`
* `nil`
* `nil?`
* `not`
* `nth`
* `number`
* `number?`
* `println`
* `prn`
* `pr-str`
* `quasiquote`
* `quasiquoteexpand`
* `quote`
* `range`
* `readline`
* `read-string`
* `reset!`
* `rest`
* `seq`
* `sequential?`
* `slurp`
* `str`
* `string?`
* `swap!`
* `symbol`
* `symbol?`
* `throw`
* `time-ms`
* `true`
* `true?`
* `try`
* `vals`
* `vec`
* `vector`
* `vector?`
* `with-meta`
* `PPP`
* `WWW`
* `XXX`
* `YYY`
* `ZZZ`


# Roadmap

The next major things to add are:

* Multi-arity function/macro definition and application
* Namespaces
* Lambdas
* lingy.core libary
* Regex support


# See Also

* [YAMLScript](https://metacpan.org/pod/YAMLScript)
* [YAMLTest](https://metacpan.org/pod/YAMLTest)


# Status

Lingy is in ALPHA status.


# Authors

* Ingy döt Net <ingy@ingy.net>


# Copyright and License

Copyright 2023 by Ingy döt Net

This is free software, licensed under:

The MIT (X11) License

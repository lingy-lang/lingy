Lingy
=====

Do for Perl what Clojure did for Java


# Synopsis

Run the Lingy REPL:

```
$ lingy
Welcome to Lingy [perl]

user=> (p<TAB>
pos?     println  prn      pr-str
user=> (prn "Hello, world!")
"Hello, world!"
nil
user=>
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


# Status

Lingy is in ALPHA status.

It has:

* The `eg` directory of example programs that work
* A pretty good REPL
  * Tab completion
  * Command history
  * History search
  * Parentheses visual matching
  * Other nice readline features

To Do:

* AOT and JIT compile to LLVM bytecode
* Compile to native Perl code


# Description

Lingy is an implementation of the Clojure language that is written in Perl and
hosted by Perl and LLVM.
Programs and modules written in Lingy have full access to Perl and its CPAN
modules.

Perl modules can be written in Lingy and distributed on CPAN.
Since Lingy code is compiled to LLVM, it should perform on the same order of
magnitude as XS modules.

Since Lingy is a complete Clojure implementation, it should be able to run
programs written in Clojure and make use of libraries written in Clojure.

Clojure is a language that cleanly solves many of the problems of Java
including making concurrency simple, and writing functional programs with
mostly immutable data types.
It is a Lisp dialect that is hosted by Java and compiles to JVM byte code.
It has access to any libraries that target the JVM.

Much of the Clojure language is written in Clojure (self hosted) and Lingy
actually uses the Clojure source code.
A variant of Clojure called ClojureScript uses the same Clojure source code but
is hosted by JavaScript with full access to NPM modules.
Lingy also intends to eventually be ported to and hosted by many other
programming languages.

Lingy started as a Perl [implementation](
https://github.com/ingydotnet/mal/tree/perl.2/impls/perl.2) of the
[Make a Lisp](https://github.com/kanaka/mal) project.
This provided a bare-bones Clojure-inspired Lisp interpreter from which Lingy
has grown upon.

# Installation

```
cpanm Lingy
```

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


# Roadmap

The next major things to add are:

* Compilation to Perl code
* Compilation to LLVM bytecode
* Lambdas


# See Also

* [YAMLScript](https://metacpan.org/pod/YAMLScript)
* [YAMLTest](https://metacpan.org/pod/YAMLTest)



# Authors

* Ingy döt Net <ingy@ingy.net>


# Copyright and License

Copyright 2023 by Ingy döt Net

This is free software, licensed under:

The MIT (X11) License

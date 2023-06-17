Lingy
=====

A Perl implementation of Clojure


# Synopsis

Run the Lingy REPL:

```
$ lingy
Lingy 0.1.12 [perl]

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
$ wget -q https://raw.githubusercontent.com/ingydotnet/lingy/main/eg/99-bottles.ly
```

```
$ cat 99-bottles.ly
(defn main [number]
  (let [
    paragraphs (map paragraph (range number 0 -1)) ]
    (map println paragraphs)))

(defn paragraph [num]
  (str
    (bottles num) " of beer on the wall,\n"
    (bottles num) " of beer.\n"
    "Take one down, pass it around.\n"
    (bottles (dec num)) " of beer on the wall.\n"))

(defn bottles [n]
  (cond
    (= n 0) "No more bottles"
    (= n 1) "1 bottle"
    :else (str n " bottles")))

(main (nth *ARGV* 0 99))
```

```
$ lingy 99-bottles.ly 3
3 bottles of beer on the wall,
3 bottles of beer.
Take one down, pass it around.
2 bottles of beer on the wall.

2 bottles of beer on the wall,
2 bottles of beer.
Take one down, pass it around.
1 bottle of beer on the wall.

1 bottle of beer on the wall,
1 bottle of beer.
Take one down, pass it around.
No more bottles of beer on the wall.
```


# Status

Lingy is in ALPHA status.


# Description

Lingy is an implementation of the Clojure language that is written in Perl and
hosted by Perl.
Programs and modules written in Lingy have full access to Perl and its CPAN
modules.

Perl modules can be written in Lingy and distributed on CPAN.
(In the future) Lingy code is compiled to a bytecode and should perform on the
same order of magnitude as XS modules.

Since Lingy will be a complete Clojure implementation, it should be able to run
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


# Lingy REPL Usage

If you run `lingy --repl` (or just `lingy`) you will start a Lingy interactive
REPL.
You can run Lingy commands and see the output.

The REPL has command line history to save all your commands.
It also has readline history search (ctl-r) and tab completion.

## Using the Clojure REPL in the Lingy REPL

If you have Clojure installed on your system and you run this command in the
Lingy REPL: `(clojure-repl-on)`, then every command you enter will be evaluated
both by Lingy and Clojure.
Run `(clojure-repl-off)` to turn it off.
Start the Lingy REPL with `lingy --clj` to turn it on from the start.

Also if you run a command like `;;;(source first)` it will only run on Clojure.
The command is a comment to Lingy but the REPL will remove the `;;;` and pass
it to Clojure.

Using this feature is a great way to compare how Lingy and Clojure work.
Eventually they should be very close to identical but currently Lingy is still
a baby.


# Differences from Clojure

Lingy intends to be a proper "Clojure Platform"; a complete port of Clojure to
Perl and other languages.

That said, differences must exist.

* The Lingy platform host language is currently just Perl.
  It is the intent to extend the language set to Python and others soon.
* Lingy currently only supports a subset of Clojure libraries (most notably
  clojure.core).
  It is intended that Lingy will eventually use Clojure's libraries directly
  starting with clojure.core.
  As of this release Lingy can `read-string` all of clojure.core and it
  converts the forms it fully supports into the lingy.core namespace.
* Lingy tries to map Clojure namespace and Java class symbols/files to Lingy
  namespace and Perl module/class symbols/files.
  * The `clojure.core` namespace equivalent in Lingy is `lingy.core` and maps
    to a file name called `lib/Lingy/core.ly` in the Lingy source code.
  * The `lingy.lang.HashMap` symbol maps to the `Lingy::HashMap` module (the
    `lib/Lingy/HashMap.pm` file).
  * More mapping details to be added here later.
* The `#?` reader macro uses the `:lingy/pl` keyword to conditionally use forms
  that the Lingy/Perl platform supports.
* Special global vars (earmuffs) that are unique to Lingy:
  * `*lingy-version*`
    Like `*clojure-version*` but for Lingy's version.
  * `*LANG*`
    Set to `"Lingy"`.
  * `*HOST*`
    Set to `"perl"`.
  * `*clojure-repl*`
    Boolean (default `false`) indicates whether Lingy REPL should also send
    input to a Clojure REPL.
* Lingy error messages currently try to be close to the Clojure ones.
  * This isn't always possible or desirable.
  * Error messages may be completely overhauled to give better info.

Certainly there are other differences and this section will be improved over
time.


# See Also

* [Clojure](https://clojure.org/)
* [YAMLScript](https://metacpan.org/pod/YAMLScript)
* [Test::More::YAMLScript](https://metacpan.org/pod/Test::More::YAMLScript)


# Authors

* Ingy döt Net <ingy@ingy.net>


# Copyright and License

Copyright 2023 by Ingy döt Net

This is free software, licensed under:

The MIT (X11) License

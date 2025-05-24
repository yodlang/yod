(lang dune 3.13)

(using menhir 3.0)

(name yod)

(generate_opam_files)

(source
 (github yodlang/yod))

(maintainers "Milesime <213074881+milesime@users.noreply.github.com>")

(authors "Milesime <213074881+milesime@users.noreply.github.com>")

(license GPL-3.0-only)

(package
 (name yod)
 (synopsis "The Yod programming language")
 (description "Yod is a purely functional programming language.")
 (depends
  (ocaml
   (>= 5))
  sedlex
  menhir
  menhirLib
  ppx_deriving
  uuseg
  yojson)
 (tags
  (language functional pure lang)))

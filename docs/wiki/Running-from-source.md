<!--
SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>

SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Running from source

You will need to have [OCaml](https://ocaml.org/) version 5.0.0 or later [installed on your system](https://ocaml.org/docs/installing-ocaml) along side [opam](https://opam.ocaml.org/) (which is the preferred install method).

You will then be able to run the following commands:

```sh
git clone https://github.com/yodlang/yod.git
cd yod
opam install --deps-only .
dune exec yod -- …
```

You can also just use [Nix](https://nixos.org/) without the above requirements:

```sh
nix run github:yodlang/yod …
```

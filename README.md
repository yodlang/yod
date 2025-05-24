<!--
SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>

SPDX-License-Identifier: CC-BY-SA-4.0
-->

<div align="center">
  <br />
  <picture>
    <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/yodlang/.github/main/media/brand-dark.png">
    <img src="https://raw.githubusercontent.com/yodlang/.github/main/media/brand-light.png" alt="Yod" width="400">
  </picture>
  <p align="center">
    <br />
    The Yod programming language.
    <br />
    <a href="https://github.com/yodlang/vscode-yod">VS Code Extension</a> •
    <a href="#usage">Usage</a> •
    <a href="#installation">Installation</a> •
    <a href="#contributing">Contributing</a> •
    <a href="#license">License</a>
  </p>
</div>

## Features

- Purely functional
  - No side effects
  - Pattern matching
  - Polymorphism
- VS Code language support
  - Syntax highlighting
  - Formatting
  - Parsing
- Helpful error messages
- Unicode support

## Examples

#### Summation

```yod
def sum lst =
  match lst {
    [] -> 0;
    [hd, tl...] -> hd + sum tl;
  }
```

#### Fibonacci

```yod
def fib n : Int -> Int =
  if n <= 1 then n else fib (n - 1) + fib (n - 2)
```

#### Grammar

For a detailed presentation of the Yod syntax and features, please have a look at [our sample grammar file](https://github.com/yodlang/yod/blob/main/examples/grammar.yod).

You can also take a look at a more fleshed out program like [our implementation of Conway’s Game of Life](https://github.com/yodlang/yod/blob/main/examples/conway.yod).

## Usage

You can skip installation when [running from source](https://github.com/yodlang/yod/wiki/Running-from-source).

The expected file extension of the Yod programming language is `.yod`.

Following [docopt](http://docopt.org/) conventions:

| Command                | Description                                       |
| :--------------------- | :------------------------------------------------ |
| `yod`                  | Parse standard input and display the AST.         |
| `yod <file>`           | Parse a file and display the AST.                 |
| `yod fmt`              | Format standard input and output it.              |
| `yod fmt <file>`       | Format a file and overwrite it.                   |
| `yod transpile`        | Transpile standard input and output it.           |
| `yod transpile <file>` | Transpile a file and write its OCaml counterpart. |

You can run transpiled files using:

```sh
ocaml <file.ml>
```

## Installation

If you are using [NixOS](https://nixos.org/), please follow [these steps](https://github.com/yodlang/yod/wiki/Installation-on-NixOS).

Or, download [the latest executable](https://github.com/yodlang/yod/releases/latest) for your system and [add it to your PATH](https://github.com/yodlang/yod/wiki/Adding-Yod-to-the-PATH).

On Unix-like operating systems, you will then need to run the following command:

```sh
chmod +x /path/to/yod/executable
```

## Contributing

We welcome contributions to Yod! If you’re interested in helping improve the language, fix bugs, or add new features, please check out our [contributing guide](https://github.com/yodlang/yod/blob/main/docs/CONTRIBUTING.md) for detailed information on how to get started, set up your development environment, and submit your contributions.

Key areas where you can contribute include:

- Improving the back-end
- Enhancing language features
- Writing documentation
- Creating examples and tutorials
- Reporting and fixing bugs
- Suggesting and implementing new features

Whether you’re a seasoned OCaml developer or just getting started with functional programming, there are many ways to contribute. We appreciate all forms of contribution and look forward to collaborating with you!

## License

This project is licensed under multiple licenses in accordance with the recommendations of the [REUSE Initiative](https://reuse.software/). Please refer to the individual files for more information.

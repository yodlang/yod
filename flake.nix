# SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
#
# SPDX-License-Identifier: GPL-2.0-only

{
  description = "The Yod programming language";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      forAllSystems = f: with nixpkgs; lib.genAttrs lib.systems.flakeExposed (s: f legacyPackages.${s});
    in
    rec {
      packages = forAllSystems (pkgs: rec {
        default = yod;
        yod = pkgs.ocamlPackages.buildDunePackage rec {
          pname = "yod";
          version = "2025.6.29";
          src = self;
          strictDeps = false;
          buildInputs = with pkgs.ocamlPackages; [
            sedlex
            menhir
            menhirLib
            ppx_deriving
            uuseg
            yojson
          ];
          buildPhase = ''
            runHook preBuild
            dune build --profile release -p ${pname} ''${enableParallelBuilding:+-j $NIX_BUILD_CORES}
            runHook postBuild
          '';
          meta = {
            description = "The Yod programming language";
            homepage = "https://github.com/yodlang/yod";
            license = with pkgs.lib.licenses; [
              gpl2Only
              cc-by-sa-40
              cc0
            ];
            maintainers = [
              {
                name = "Milesime";
                email = "213074881+milesime@users.noreply.github.com";
                github = "milesime";
                githubId = 213074881;
              }
            ];
            inherit (pkgs.ocaml.meta) platforms;
          };
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell.override { stdenv = pkgs.fastStdenv; } {
          inputsFrom = with pkgs; lib.attrValues packages.${system};
          packages =
            with pkgs;
            [
              packages.${system}.default
              reuse
              just
            ]
            ++ (with ocamlPackages; [
              ocaml-lsp
              utop
              ocamlformat_0_27_0
            ]);
        };
      });
    };
}

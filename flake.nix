# SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>
#
# SPDX-License-Identifier: GPL-3.0-only

{
  description = "The Yod programming language";

  inputs = {
    nixpkgs.url = "github:nix-ocaml/nix-overlays";
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
          version = "0.0.0";
          src = self;
          strictDeps = false;
          stdenv = pkgs.fastStdenv;
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
          checkPhase = ''
            runHook preCheck
            dune runtest --profile release -p ${pname} ''${enableParallelBuilding:+-j $NIX_BUILD_CORES}
            runHook postCheck
          '';
          installPhase = ''
            runHook preInstall
            dune install --profile release --prefix $out --libdir $OCAMLFIND_DESTDIR ${pname} --docdir $out/share/doc --mandir $out/share/man
            runHook postInstall
          '';
          meta = {
            description = "The Yod programming language";
            homepage = "https://github.com/yodlang/yod";
            license = with pkgs.lib.licenses; [
              gpl3Only
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
          inputsFrom = pkgs.lib.attrValues packages.${pkgs.system};
          packages =
            with pkgs;
            [
              reuse
              just
              ocamlformat_0_27_0
            ]
            ++ (with ocamlPackages; [
              ocaml-lsp
              utop
            ]);
        };
      });
    };
}

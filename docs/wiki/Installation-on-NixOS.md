<!--
SPDX-FileCopyrightText: 2025 Milesime <213074881+milesime@users.noreply.github.com>

SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Installation on NixOS

Add the Yod input and inherit `inputs` in your `flake.nix` configuration for your system and for [Home Manager](https://nix-community.github.io/home-manager/) if you have it:

```nix
{
  inputs = {
    …
    yod = {
      url = "github:yodlang/yod";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    {
      nixosConfigurations.host = nixpkgs.lib.nixosSystem {
        …
        specialArgs = {
          inherit inputs;
        };
        modules = [
          …
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              …
              extraSpecialArgs = {
                inherit inputs;
              };
            };
          }
        ];
      };
    };
}
```

You can then install Yod as a system package:

```nix
{ …, pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    …
    inputs.yod.packages.${system}.default
  ];
}
```

Or as a user package with [Home Manager](https://nix-community.github.io/home-manager/):

```nix
{ …, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    …
    inputs.yod.packages.${system}.default
  ];
}
```

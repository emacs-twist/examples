{
  description = "Pure Emacs apps";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    twist = {
      url = "github:emacs-twist/twist.nix";
    };
    org-babel.url = "github:emacs-twist/org-babel";

    melpa = {
      url = "github:melpa/melpa";
      flake = false;
    };
    gnu-elpa = {
      url = "git+https://git.savannah.gnu.org/git/emacs/elpa.git?ref=main";
      flake = false;
    };
    nongnu = {
      url = "git+https://git.savannah.gnu.org/git/emacs/nongnu.git?ref=main";
      flake = false;
    };
    epkgs = {
      url = "github:emacsmirror/epkgs";
      flake = false;
    };

    emacs = {
      url = "github:emacs-mirror/emacs";
      flake = false;
    };

    emacs-unstable.url = "github:nix-community/emacs-overlay";

    # Configuration repositories
    terlar = {
      url = "github:terlar/emacs-config";
      # Simply import as an Emacs configuration repository
      flake = false;
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , ...
    } @ inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        inherit (nixpkgs) lib;

        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            inputs.emacs-unstable.overlay
            inputs.org-babel.overlay
            inputs.twist.overlay
            (pkgs': _super: {
              emacs_28 = pkgs'.emacsUnstable.overrideAttrs (_: { version = "28.0.90"; });
            })
          ];
        };

        inventories = import ./lib/inventories.nix inputs;

        profiles = {
          terlar = {
            emacsPackage = pkgs.emacs_28;
            lockDir = ./profiles/terlar/lock;
            initFiles = [
              (pkgs.tangleOrgBabelFile "init.el" (inputs.terlar + "/init.org") { })
            ];
            extraPackages = [
              "use-package"
              "readable-typo-theme"
              "readable-mono-theme"
            ];
            extraRecipeDir = ./profiles/terlar/recipes;
            extraInputOverrides = {
              readable-typo-theme = _: _: {
                src = inputs.terlar;
              };
              readable-mono-theme = _: _: {
                src = inputs.terlar;
              };
            };
          };
        };
      in
        rec {
          packages = lib.pipe profiles [
            (lib.mapAttrsToList (name: attrs:
              let
                package = pkgs.callPackage ./lib/profile.nix ({
                  inherit inventories;
                  withSandbox = pkgs.callPackage ./lib/sandbox.nix { };
                } // attrs);
              in
                [
                  {
                    inherit name;
                    value = package;
                  }
                  {
                    name = "${name}-admin";
                    value = package.admin "profiles/${name}/lock";
                  }
                ]))
            builtins.concatLists
            builtins.listToAttrs
          ];
        });
}

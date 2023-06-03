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
    scimax = {
      url = "github:jkitchin/scimax";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    twist,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem
    (system: let
      inherit (nixpkgs) lib;

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          inputs.org-babel.overlays.default
          inputs.twist.overlays.default
        ];
      };

      inventories = import ./lib/inventories.nix inputs;

      inherit (inputs.emacs-unstable.packages.${system}) emacs-unstable emacs-git;

      profiles = {
        terlar = import ./profiles/terlar {
          inherit pkgs;
          inherit (inputs) terlar;
          emacsPackage = emacs-git;
        };

        scimax = import ./profiles/scimax {
          inherit pkgs;
          inherit (inputs) scimax;
          emacsPackage = emacs-unstable;
          inherit
            (twist.lib {inherit lib;})
            parseUsePackages
            emacsBuiltinLibraries
            ;
        };
      };

      packages =
        lib.mapAttrs (
          _: attrs:
            pkgs.callPackage ./lib/profile.nix ({
                inherit inventories;
                withSandbox = pkgs.callPackage ./lib/sandbox.nix {};
              }
              // attrs)
        )
        profiles;
    in {
      inherit packages;
      apps = lib.pipe packages [
        (lib.mapAttrsToList (
          name: package: let
            apps = package.makeApps {
              lockDirName = "profiles/${name}/lock";
            };
          in
            lib.mapAttrsToList (appName: app: {
              name = "${appName}-${name}";
              value = app;
            })
            apps
        ))
        lib.concatLists
        lib.listToAttrs
      ];
    });
}

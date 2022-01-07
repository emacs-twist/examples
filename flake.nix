{
  description = "Pure Emacs apps";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    twist = {
      url = "github:akirak/emacs-twist/devel";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    org-babel.url = "github:akirak/nix-org-babel";

    melpa = {
      url = "github:melpa/melpa";
      flake = false;
    };
    gnu-elpa = {
      url = "git+https://git.savannah.gnu.org/git/emacs/elpa.git?ref=main";
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

        profiles = lib.mapAttrs
          (name: attrs: pkgs.callPackage ./lib/profile.nix ({
            inherit inventories;
            withSandbox = pkgs.callPackage ./lib/sandbox.nix { };
          } // attrs))
          {
            terlar = {
              emacsPackage = pkgs.emacs_28;
              lockDir = ./profiles/terlar/lock;
              initFiles = [
                (pkgs.tangleOrgBabelFile "init.el" (inputs.terlar + "/init.org") { })
              ];
            };
          };
      in
        rec {
          packages = flake-utils.lib.flattenTree profiles;

          apps = {
            lock = flake-utils.lib.mkApp {
              drv = profiles.terlar.lock.writeToDir "profiles/terlar/lock";
            };
          } // lib.mapAttrs (name: package: flake-utils.lib.mkApp {
            drv = package.sandboxed;
          }) profiles;
        });
}

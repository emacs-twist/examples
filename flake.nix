{
  description = "Pure Emacs apps";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

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
    , pre-commit-hooks
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

        inventories = import ./inventories.nix inputs;

        profiles = lib.mapAttrs
          (name: path: pkgs.callPackage path {
            src = inputs.${name};
            org-babel = inputs.org-babel.lib;
            inherit inventories;
            inputOverrides = import ./inputs.nix { inherit (pkgs) lib; };
          })
          {
            terlar = ./profiles/terlar;
          };
      in
      rec {
        packages = flake-utils.lib.flattenTree {
          inherit (profiles) terlar;
        };

        apps.lock = flake-utils.lib.mkApp {
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              nix-linter.enable = true;
            };
          };
        };
        devShell = pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          drv = profiles.terlar.lock.writeToDir "profiles/terlar/lock";
        };
      });
}

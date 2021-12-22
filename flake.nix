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
    nongnu-elpa = {
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

        inventories = [
          {
            type = "melpa";
            path = ./recipes;
          }
          {
            type = "elpa-core";
            path = inputs.gnu-elpa.outPath + "/elpa-packages";
            src = inputs.emacs.outPath;
          }
          {
            name = "melpa";
            type = "melpa";
            path = inputs.melpa.outPath + "/recipes";
            exclude = [
              "pdf-tools"
              "bbdb"
              "slime"
            ];
          }
          {
            name = "gnu";
            type = "archive";
            url = "https://elpa.gnu.org/packages/";
          }
          # Duplicate attribute set for the locked packages, but would be no
          # problem in functionality.
          {
            name = "nongnu";
            type = "archive";
            url = "https://elpa.nongnu.org/nongnu/";
          }
          {
            name = "emacsmirror";
            type = "gitmodules";
            path = inputs.epkgs.outPath + "/.gitmodules";
          }
        ];

        profiles = lib.mapAttrs
          (name: path: pkgs.callPackage path {
            src = inputs.${name};
            org-babel = inputs.org-babel.lib;
            inherit inventories;
          })
          {
            terlar = ./profiles/terlar;
          };
      in
      rec {
        packages = flake-utils.lib.flattenTree {
          inherit (profiles) terlar;
        };

        apps.update-elpa = flake-utils.lib.mkApp {
          drv = pkgs.writeShellApplication {
            name = "update-elpa";
            runtimeInputs = [
              pkgs.jq
            ];
            text = ''
              tmp=$(mktemp -t archive-XXX.lock)
              cleanup() {
                rm -f "$tmp"
              }
              trap cleanup EXIT ERR      

              cwd="$(pwd)"
              # shellcheck disable=SC2041
              for name in ${lib.escapeShellArgs (builtins.attrNames profiles)}
              do
                dir="$cwd/profiles/$name"

                if [[ ! -e "$dir/archive.lock" ]]
                then
                  touch "$dir/archive.lock"
                  git add "$dir/archive.lock"
                fi
      
                nix eval --impure --json ".#packages.${system}.$name.archiveLock" "$@" \
                  | jq \
                  > "$tmp"
                cp "$tmp" "$dir/archive.lock"
              done
            '';
          };
        };

        apps.lock = flake-utils.lib.mkApp {
          drv = pkgs.writeShellApplication {
            name = "lock";
            runtimeInputs = [
              pkgs.nixfmt
            ];
            text = ''
              cwd="$(pwd)"
              # shellcheck disable=SC2041
              for name in ${lib.escapeShellArgs (builtins.attrNames profiles)}
              do
                dir="$cwd/profiles/$name"

                if [[ ! -f "$dir/flake.nix" ]]
                then
                  touch "$dir/flake.nix"
                  git add "$dir/flake.nix"
                fi

                nix eval --impure ".#packages.${system}.$name.flakeNix" "$@" \
                | nixfmt \
                | sed -e 's/<LAMBDA>/{ ... }: { }/' \
                > "$dir/flake.nix"
                cd "$dir"
                nix flake lock

                cd "$cwd"
              done
          '';
          };
        };

       # defaultPackage = packages.hello;
        # apps.hello = flake-utils.lib.mkApp { drv = packages.hello; };
        # defaultApp = apps.hello;
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
        };
      });
}

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

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , twist
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
              emacs_28 = pkgs'.emacsUnstable.overrideAttrs (_: { version = "28.0.91"; });
            })
          ];
        };

        inventories = import ./lib/inventories.nix inputs;

        inherit (twist.lib { inherit lib; }) parseUsePackages;

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

          scimax = {
            emacsPackage = pkgs.emacs_28;
            lockDir = ./profiles/scimax/lock;
            # Twist cannot handle use-package-always-ensure well right now.
            initFiles = [ ];
            extraPackages =
              let
                files = lib.pipe (builtins.readDir inputs.scimax) [
                  (lib.filterAttrs (_: type: type == "regular"))
                  builtins.attrNames
                ];

                inherit (pkgs.callPackage ./lib/utils.nix { }) sanitizeFile;

                elispFiles =
                  (lib.pipe files [
                    (builtins.filter (lib.hasSuffix ".el"))
                    (builtins.map (filename:
                      # Nix parse strings containing control characters,
                      # and page breaks in some source files cause errors.
                      # Thus it is required to sanitize source files.
                      sanitizeFile filename (inputs.scimax + "/${filename}")
                    ))
                  ])
                  ++
                  (lib.pipe files [
                    (builtins.filter (lib.hasSuffix ".org"))
                    (builtins.map (filename:
                      pkgs.tangleOrgBabelFile "${filename}.el"
                        (inputs.scimax + "/${filename}") { }
                    ))
                  ]);

                builtinLibraries =
                  pkgs.callPackage (twist.lib { inherit lib; }).emacsBuiltinLibraries {
                    emacs = pkgs.emacs_28;
                  };

                packages = lib.pipe elispFiles [
                  (map builtins.readFile)
                  (map (parseUsePackages { alwaysEnsure = true; }))
                  (lib.catAttrs "elispPackages")
                  builtins.concatLists
                  (lib.subtractLists builtinLibraries)
                  (lib.subtractLists [
                    # Contained in the repository (check :load-path in packages.el)
                    "bibtex-hotkeys"
                    "ox-manuscript"
                    "ox-cmu"
                    "org-show"
                    "scimax-lob"
                    "scimax-md"
                    "help-fns+"
                    "org-mime"
                    "org-ref-ivy"
                    "kitchingroup"
                    "words"
                    "ore"

                    # Annoying dependency on gh
                    "gist"
                    # Write to disk during byte-compilation
                    "slack"
                    # Requires git executable during byte-compilation
                    "magithub"
                  ])
                  (builtins.filter (name: !lib.hasPrefix "scimax" name))
                ];
              in
                packages
                ++
                [
                  "use-package"
                  "diminish"
                  "bind-key"
                ];
            extraRecipeDir = ./profiles/scimax/recipes;
            extraInputOverrides = {
              ox-clip = _: super: {
                packageRequires = {
                  htmlize = "0";
                } // super.packageRequires;
              };
              ob-ipython = _: super: {
                packageRequires = builtins.removeAttrs super.packageRequires
                  [ "dash-functional" ];
              };
              ov-highlight = _: super: {
                packageRequires = {
                  ov = "0";
                } // super.packageRequires;
              };
              ox-ipynb = _: super: {
                packageRequires = {
                  dash = "0";
                } // super.packageRequires;
              };
              org-ref = _: super: {
                packageRequires = {
                  ivy-bibtex = "0";
                  helm-bibtex = "0";
                  pdf-tools = "0";
                } // super.packageRequires;
              };
              drag-stuff = _: super: {
                files = builtins.removeAttrs super.files ["drag-stuff-pkg.el"];
              };
            };
            # Due to org-babel tangling, scimax-dir needs to be writable.
            extraBubblewrapOptions = lib.pipe (builtins.readDir inputs.scimax) [
              builtins.attrNames
              (lib.subtractLists ["init.el"])
              (map (name: [
                "--symlink"
                (inputs.scimax + "/${name}")
                "$HOME/.emacs.d/${name}"
              ]))
              builtins.concatLists
            ];
            # Based on
            # <https://github.com/jkitchin/scimax/blob/253c1ec31617fa22c7624cd93027a1be37957071/init.el>
            initFileForSandbox = pkgs.writeText "init.el" ''
              (setq gc-cons-threshold 80000000)
              (defconst scimax-dir user-emacs-directory)
              (setq scimax-user-dir user-emacs-directory)
              (setq package-user-dir (locate-user-emacs-file "elpa/"))
              (setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")))
              (setq scimax-load-user-dir nil)

              (add-to-list 'load-path scimax-dir)
              ;; (add-to-list 'load-path scimax-user-dir)

              ;; bootstrap.el
              (require 'use-package)
              (setq use-package-ensure-function #'ignore)

              ;; See org-db.el
              (require 'emacsql-sqlite)

              (require 'packages)

              (set-language-environment "UTF-8")

              (setq gc-cons-threshold 800000)
              (provide 'init)
            '';
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

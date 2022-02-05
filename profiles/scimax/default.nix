{ pkgs, scimax, parseUsePackages, emacsBuiltinLibraries }:
with builtins;
let
  inherit (pkgs) lib;

  inherit (pkgs.callPackage ./../../lib/utils.nix { }) sanitizeFile;
in
{
  emacsPackage = pkgs.emacs_28;
  lockDir = ./lock;
  # Twist cannot handle use-package-always-ensure well right now.
  initFiles = [ ];
  extraPackages =
    let
      files = lib.pipe (readDir scimax) [
        (lib.filterAttrs (_: type: type == "regular"))
        attrNames
      ];

      elispFiles =
        (lib.pipe files [
          (filter (lib.hasSuffix ".el"))
          (map (filename:
            # Nix parse strings containing control characters,
            # and page breaks in some source files cause errors.
            # Thus it is required to sanitize source files.
            sanitizeFile filename (scimax + "/${filename}")
          ))
        ])
        ++
        (lib.pipe files [
          (filter (lib.hasSuffix ".org"))
          (map (filename:
            pkgs.tangleOrgBabelFile "${filename}.el"
              (scimax + "/${filename}")
              { }
          ))
        ]);

      builtinLibraries =
        pkgs.callPackage emacsBuiltinLibraries {
          emacs = pkgs.emacs_28;
        };

      packages = lib.pipe elispFiles [
        (map readFile)
        (map (parseUsePackages { alwaysEnsure = true; }))
        (lib.catAttrs "elispPackages")
        concatLists
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
        (filter (name: !lib.hasPrefix "scimax" name))
      ];
    in
    packages
    ++
    [
      "use-package"
      "diminish"
      "bind-key"
    ];
  extraRecipeDir = ./recipes;
  extraInputOverrides = {
    ox-clip = _: super: {
      packageRequires = {
        htmlize = "0";
      } // super.packageRequires;
    };
    ob-ipython = _: super: {
      packageRequires = removeAttrs super.packageRequires
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
      files = removeAttrs super.files [ "drag-stuff-pkg.el" ];
    };
  };

  sandboxArgs = config: {

    # Due to org-babel tangling, scimax-dir needs to be writable.
    extraBubblewrapOptions =
      (lib.pipe (readDir scimax) [
        attrNames
        (lib.subtractLists [ "init.el" "org-mime" ])
        (map (name: [
          "--symlink"
          (scimax + "/${name}")
          "$HOME/.emacs.d/${name}"
        ]))
        concatLists
      ])
      ++
      [
        "--ro-bind"
        (config.elispPackages.org-mime + "/share/emacs/site-lisp")
        "$HOME/.emacs.d/org-mime"
      ];

    # Based on
    # <https://github.com/jkitchin/scimax/blob/253c1ec31617fa22c7624cd93027a1be37957071/init.el>
    initFile = pkgs.writeText "init.el" ''
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
}

{ emacsTwist
, lib
, emacs_28
, inventories
, tangleOrgBabelFile
, org-babel
, src
}:
with builtins;
let
  orgFile = src + "/init.org";

  initFile = tangleOrgBabelFile "init.el" orgFile {
    languages = [ "emacs-lisp" ];
  };
in
(emacsTwist {
  emacs = emacs_28;
  initFiles = [
    initFile
  ];
  flakeLockFile = ./flake.lock;
  archiveLockFile = ./archive.lock;
  inherit inventories;
  inputOverrides = {
    bbdb = _: super: {
      packageRequires = super.packageRequires // {
        vm = "0";
      };
    };
    dired-subtree = _: super: {
      packageRequires = super.packageRequires // {
        dired-hacks-utils = "0";
      };
    };
    dired-hacks-utils = _: super: {
      packageRequires = super.packageRequires // {
        dash = "0";
      };
    };
    ghelp = _: super: {
      packageRequires = super.packageRequires // {
        sly = "0";
      };
    };
    eval-in-repl = _: super: {
      # The version specification in eval-in-repl-pkg.el is a placeholder,
      # so specify an actual version instead.
      version = "0.9.7";

      packageRequires = super.packageRequires // {
        sly = "0";
        sml-mode = "0";
      };
    };
    request = _: super: {
      packageRequires = super.packageRequires // {
        deferred = "0";
      };
    };
    ess = _: super: {
      # texinfo fails, so just remove the source file to disable the build step
      # for now.
      files = lib.pipe super.files [
        (filter (file: match ".+\.texi" file == null))
        (lib.subtractLists [".dir-locals.el"])
      ];
    };
    org-radiobutton = _: super: {
      packageRequires = super.packageRequires // {
        dash = "2";
      };
    };
    queue = _: super: {
      files = lib.subtractLists [
        "fdl.texi"
        "predictive-user-manual.texinfo"
      ] super.files;
    };
    emr = _: _: {

    };
    suggest = _: super: {
      packageRequires = super.packageRequires // {
        shut-up = "0";
      };
    };
    language-id = _: _: {
      # Until https://github.com/lassik/emacs-language-id/pull/12 is merged
      origin = {
        type = "github";
        owner = "akirak";
        repo = "emacs-language-id";
        ref = "pcase";
      };
    };
  };
})

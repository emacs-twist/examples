{ emacsTwist
, emacs_28
, inventorySpecs
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
  lockFile = ./flake.lock;
  inherit inventorySpecs;
  inputOverrides = {
    bbdb = _: super: {
      inventory = null;
      origin = {
        type = "tarball";
        url = "https://elpa.gnu.org/packages/bbdb-3.2.tar";
      };
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
    eval-in-repl = _: _: {
      # The version specification in eval-in-repl-pkg.el is a placeholder,
      # so specify an actual version instead.
      version = "0.9.7";
    };
    ess = _: super: {
      # texinfo fails, so just remove the source file to disable the build step
      # for now.
      files = filter (file: match ".+\.texi" file == null) super.files;
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

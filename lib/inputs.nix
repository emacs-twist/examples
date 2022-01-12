{ lib }:
with builtins;
{
  bbdb = _: super: {
    files = removeAttrs super.files [
      "bbdb-vm.el"
      "bbdb-vm-aux.el"
    ];
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
      helpful = "0";
      eglot = "0";
      geiser = "0";
    };
  };
  indium = _: _: {
    origin = {
      type = "github";
      owner = "akirak";
      repo = "Indium";
      ref = "fix-build-error";
    };
  };
  rustic = _: super: {
    packageRequires = {
      lsp-mode = "0";
      flycheck = "0";
    } // super.packageRequires;
  };
  eval-in-repl = _: super: {
    # The version specification in eval-in-repl-pkg.el is a placeholder,
    # so specify an actual version instead.
    version = "0.9.7";

    packageRequires = super.packageRequires // {
      sly = "0";
      dash = "2";
      paredit = "0";
      ace-window = "0";
      # These must be major-mode specific ones.
      # You may filter lispFiles if you don't want them.
      sml-mode = "0";
      cider = "0";
      elm-mode = "0";
      erlang = "0";
      geiser = "0";
      hy-mode = "0";
      elixir-mode = "0";
      js-comint = "0";
      lua-mode = "0";
      tuareg = "0";
      alchemist = "0";
      racket-mode = "0";
      inf-ruby = "0";
      slime = "0";
    };
  };
  org-babel-eval-in-repl = _: super: {
    files = removeAttrs super.files [
      "eval-in-repl-ess.el"
      # "eval-in-repl-matlab.el"
    ];
  };
  request = _: super: {
    packageRequires = super.packageRequires // {
      deferred = "0";
    };
  };
  ess = _: super: {
    files = removeAttrs super.files [".dir-locals.el"];
  };
  org-radiobutton = _: super: {
    packageRequires = super.packageRequires // {
      dash = "2";
    };
  };
  smartparens = _: super: {
    packageRequires = {
      dash = "2";
    } // super.packageRequires;
  };
  emr = _: _: {
    origin = {
      type = "github";
      owner = "akirak";
      repo = "emacs-refactor";
      ref = "require-compile";
    };
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
  js2-refactor = _: super: {
    packageRequires = {
      dash = "0";
      yasnippet = "0";
      s = "0";
      multiple-cursors = "0";
      js2-mode = "0";
    } // super.packageRequires;
  };
}

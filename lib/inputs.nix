{lib}:
with builtins; {
  ghelp = _: super: {
    packageRequires =
      super.packageRequires
      // {
        sly = "0";
        helpful = "0";
        eglot = "0";
        geiser = "0";
      };
  };
  counsel = _: super: {
    files = removeAttrs super.files [
      "elpa.el"
      "ivy-avy.el"
      "ivy-faces.el"
      "ivy-hydra.el"
      "ivy-overlay.el"
      "ivy.el"
      "swiper.el"
    ];
  };
  rustic = _: super: {
    packageRequires =
      {
        lsp-mode = "0";
        flycheck = "0";
      }
      // super.packageRequires;
  };
  eval-in-repl = _: super: {
    # The version specification in eval-in-repl-pkg.el is a placeholder,
    # so specify an actual version instead.
    version = "0.9.7";

    packageRequires =
      super.packageRequires
      // {
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
  suggest = _: super: {
    packageRequires =
      super.packageRequires
      // {
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
  lispy = _: super: {
    # le-js depends on indium, which I don't want to install.
    files = builtins.removeAttrs super.files ["le-js.el"];
  };
  helm = _: super: {
    files = removeAttrs super.files [".dir-locals.el"];
  };
  emacsql = _: super: {
    packageRequires =
      {
        sqlite = "0";
        sqlite3 = "0";
      }
      // super.packageRequires;
  };
}

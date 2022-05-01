{
  emacsTwist,
  lib,
  cmake,
  gcc,
  sqlite,
  libvterm-neovim,
  withSandbox,
  inventories,
  # Profile-specific
  emacsPackage,
  initFiles,
  lockDir,
  extraPackages,
  extraRecipeDir,
  extraInputOverrides,
  sandboxArgs ? _: {},
}:
with builtins; let
  package =
    (emacsTwist {
      inherit initFiles;
      inherit emacsPackage;
      inherit lockDir;
      inherit extraPackages;
      inventories =
        [
          {
            type = "melpa";
            path = extraRecipeDir;
          }
        ]
        ++ inventories;
      inputOverrides = (import ./inputs.nix {inherit lib;}) // extraInputOverrides;
    })
    .overrideScope' (self: super: {
      elispPackages = super.elispPackages.overrideScope' (eself: esuper: {
        vterm = esuper.vterm.overrideAttrs (old: {
          # Based on the configuration in nixpkgs available at the following URL:
          # https://github.com/NixOS/nixpkgs/blob/af21d41260846fb9c9840a75e310e56dfe97d6a3/pkgs/applications/editors/emacs/elisp-packages/melpa-packages.nix#L483
          nativeBuildInputs = [cmake gcc];
          buildInputs = old.buildInputs ++ [libvterm-neovim];
          cmakeFlags = [
            "-DEMACS_SOURCE=${super.emacs.src}"
          ];
          preBuild = ''
            mkdir -p build
            cd build
            cmake ..
            make
            install -m444 -t . ../*.so
            install -m600 -t . ../*.el
            cp -r -t . ../etc
            rm -rf {CMake*,build,*.c,*.h,Makefile,*.cmake}
          '';
        });

        pdf-tools = esuper.pdf-tools.overrideAttrs (old: {
          preBuild = ''
            mkdir build
          '';
        });

        emacsql-sqlite = esuper.emacsql-sqlite.overrideAttrs (old: {
          buildInputs = old.buildInputs ++ [sqlite];

          postBuild = ''
            cd sqlite
            make
            cd ..
          '';
        });

        # Exclude info outputs that fail to build.

        sml-mode = esuper.sml-mode.overrideAttrs (old: {
          outputs = ["out"];
        });

        geiser = esuper.geiser.overrideAttrs (old: {
          outputs = ["out"];
        });

        ess = esuper.ess.overrideAttrs (old: {
          outputs = ["out"];
        });

        queue = esuper.queue.overrideAttrs (old: {
          outputs = ["out"];
        });

        # scimax
        # > ov-highlight.el:170:1: Error: Wrong type argument: proper-list-p, (p . v)
        ov-highlight = esuper.ov-highlight.overrideAttrs (old: {
          dontByteCompile = true;
        });
      });
    });
in
  lib.extendDerivation true {
    sandboxed = withSandbox package sandboxArgs;
  }
  package

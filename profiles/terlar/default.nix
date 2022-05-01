{
  pkgs,
  terlar,
}: {
  emacsPackage = pkgs.emacsUnstable;
  sandboxArgs = {};
  lockDir = ./lock;
  initFiles = [
    (pkgs.tangleOrgBabelFile "init.el" (terlar + "/init.org") {})
  ];
  extraPackages = [
    "use-package"
    "readable-typo-theme"
    "readable-mono-theme"
  ];
  extraRecipeDir = ./recipes;
  extraInputOverrides = {
    readable-typo-theme = _: _: {
      src = terlar;
    };
    readable-mono-theme = _: _: {
      src = terlar;
    };
  };
}

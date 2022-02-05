{ pkgs, terlar }:
{
  emacsPackage = pkgs.emacs_28;
  lockDir = ./lock;
  initFiles = [
    (pkgs.tangleOrgBabelFile "init.el" (terlar + "/init.org") { })
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

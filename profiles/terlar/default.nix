{
  pkgs,
  terlar,
}: {
  emacsPackage = pkgs.emacsGit;
  lockDir = ./lock;
  initFiles = [
    (pkgs.tangleOrgBabelFile "init.el" (terlar + "/init.org") {})
  ];
  extraPackages = [
    "use-package"
    "pairable"
    "readable"
    "readable-typo-theme"
    "readable-mono-theme"
  ];
  extraRecipeDir = ./recipes;
  extraInputOverrides = {
    pairable = _: _: {
       src = terlar;
     };
    readable = _: _: {
      src = terlar;
    };
    readable-typo-theme = _: _: {
      src = terlar;
    };
    readable-mono-theme = _: _: {
      src = terlar;
    };
  };
}

{ emacsTwist
, lib
, emacs_28
, inventories
, tangleOrgBabelFile
, org-babel
, src
, inputOverrides
}:
with builtins;
let
  orgFile = src + "/init.org";

  initFile = tangleOrgBabelFile "init.el" orgFile { };
in
(emacsTwist {
  emacsPackage = emacs_28;
  initFiles = [
    initFile
  ];
  lockDir = ./lock;
  inherit inventories;
  inherit inputOverrides;
})

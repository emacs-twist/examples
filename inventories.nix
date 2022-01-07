inputs:
[
  {
    type = "melpa";
    path = ./recipes;
  }
  {
    type = "elpa-core";
    path = inputs.gnu-elpa.outPath + "/elpa-packages";
    src = inputs.emacs.outPath;
  }
  {
    name = "melpa";
    type = "melpa";
    path = inputs.melpa.outPath + "/recipes";
    exclude = [
      "pdf-tools"
      "bbdb"
      "slime"
    ];
  }
  {
    name = "gnu";
    type = "archive";
    url = "https://elpa.gnu.org/packages/";
  }
  # Duplicate attribute set for the locked packages, but would be no
  # problem in functionality.
  {
    name = "nongnu";
    type = "archive";
    url = "https://elpa.nongnu.org/nongnu/";
  }
  {
    name = "emacsmirror";
    type = "gitmodules";
    path = inputs.epkgs.outPath + "/.gitmodules";
  }
]

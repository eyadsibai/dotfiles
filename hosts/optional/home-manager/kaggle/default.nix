{ pkgs
, lib
, ...
}:
let
  secrets = import ../../../../secrets;
in
{
  home.packages = [ pkgs.kaggle ];
  xdg.configFile.".kaggle/kaggle.json".text =
    lib.generators.toJSON { } {
      username = "eyadsibai";
      key = "${secrets.kaggle.key}";
    };
}

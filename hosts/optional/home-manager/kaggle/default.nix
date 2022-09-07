{ pkgs
, lib
, ...
}:
let
  secrets = import ../../../secrets;
in
{
  xdg.configFile.".kaggle/kaggle.json" =
    lib.generators.toJSON { } {
      username = "eyadsibai";
      key = "${secrets.kaggle.key}";
    };
}

{ pkgs
, lib
, ...
}:
let
  secrets = import ../../../../../secrets;
in
{
  home.packages = [ pkgs.kaggle ];
  home.file.".kaggle/kaggle.json".text =
    lib.generators.toJSON { } {
      username = "eyadsibai";
      key = "${secrets.kaggle.key}";
    };
}

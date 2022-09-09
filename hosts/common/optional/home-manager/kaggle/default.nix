{ pkgs
, lib
, config
, ...
}: {
  home.packages = [ pkgs.kaggle ];
  home.file.".kaggle/kaggle.json".text = lib.generators.toJSON { } {
    username = "eyadsibai";
    key = "${config.secrets.apps.kaggle.key}";
  };
}

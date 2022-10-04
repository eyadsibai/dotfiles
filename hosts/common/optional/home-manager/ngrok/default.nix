{ pkgs
, hostname
, lib
, config
, # , modulesPath
  ...
}: {
  home.packages = [
    pkgs.ngrok
  ];
  xdg.configFile."ngrok/ngrok.yml" = lib.mkIf (builtins.elem pkgs.ngrok config.home.packages) {
    text = lib.generators.toYAML { } {
      version = "2";
      authtoken = "${config.secrets.${hostname}.ngrok.authtoken}";
    };
  };
}

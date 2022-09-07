{ pkgs
, hostname
, lib
, ...
}:
let
  secrets = import ../../../secrets;
in
{
  home.packages = [
    pkgs.ngrok
  ];
  xdg.configFile."ngrok/ngrok.yml".text = lib.generators.toYAML { } {
    version = "2";
    authtoken = "${secrets.${hostname}.ngrok.authtoken}";
  };

}

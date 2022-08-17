{ pkgs
, ...
}:
# let
#   secrets = import ../../../../secrets;
# in
{
  home.packages = [
    pkgs.ngrok
  ];
  xdg.configFile."ngrok/ngrok.yml".text = ''
    version: "2"
    authtoken: ${secrets.eyad-nixos.ngrok.authtoken}
  '';
}

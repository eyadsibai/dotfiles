{ config
, pkgs
, secrets
, ...
}:
{
  xdg.configFile."ngrok/ngrok.yml".text = ''
    version: "2"
    authtoken: ${secrets.ngrok.authtoken}
  '';
}

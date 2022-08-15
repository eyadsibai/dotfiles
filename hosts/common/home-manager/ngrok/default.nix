{ config
, pkgs
  # , authtoken
, ...
}:
{
  xdg.configFile."ngrok/ngrok.yml".text = ''
    version: "2"

  '';
  # authtoken: ${authtoken}
}

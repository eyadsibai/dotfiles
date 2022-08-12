{ config
, pkgs
, ...
}:
{ xdg.configFile."ngrok/ngrok.yml".source = config.lib.file.mkOutOfStoreSymlink ./files/ngrok.yml; }

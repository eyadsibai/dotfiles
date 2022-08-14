{ config
, pkgs
, ...
}:
{ xdg.configFile."ngrok/ngrok.yml".source = ./ngrok.yml; }

# Proxy tools for MitM scenarios
{ pkgs ? import <nixpkgs> { }
, ...
}:
{
  environment.systemPackages =
    with pkgs; [ bettercap burpsuite ettercap mitmproxy mubeng proxify proxychains redsocks rshijack zap ];
}

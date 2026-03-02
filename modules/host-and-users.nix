# Host and user configuration for both Linux (NixOS) and Darwin (macOS)
# Arguments: lib, pkgs, specialArgs, ...
{ lib, pkgs, specialArgs, ... }:

let
  username = specialArgs.username;
  hostname = specialArgs.hostname;
  linuxUserAttrs = lib.optionalAttrs pkgs.stdenv.isLinux {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };
  darwinHostAttrs = lib.optionalAttrs pkgs.stdenv.isDarwin {
    networking.computerName = hostname;
    system.defaults.smb.NetBIOSName = hostname;
  };
in
lib.mkMerge [
  (lib.mkIf (hostname != null) { networking.hostName = hostname; })
  (lib.mkIf pkgs.stdenv.isDarwin darwinHostAttrs)
  (lib.mkIf (username != null) {
    users.users."${username}" = {
      description = username;
    } // linuxUserAttrs;
    nix.settings.trusted-users = [ username ] ++ (lib.optionals pkgs.stdenv.isLinux [ "root" ]);
  })
]

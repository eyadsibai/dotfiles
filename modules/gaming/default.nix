{ config, pkgs, lib, ... }:

let
  # Alias for the main gaming configuration
  gamingCfg = config.services.gaming;
  # Alias for emulator specific configuration, nested under gamingCfg
  emulatorsSpecificCfg = gamingCfg.emulators;
in
{
  imports = [
    ./steam.nix
    ./emulation # Updated import path
    ./streaming.nix
  ];

  options = {
    services.gaming = {
      enable = lib.mkEnableOption "Enable all gaming features (Steam, Lutris, Emulators, etc.)";

      emulators = {
        pc = lib.mkEnableOption "retro PC emulators (applies if services.gaming.enable is true)";
        retroarchExtraConfig = lib.mkOption {
          default = { };
          example = {
            video_driver = "vulkan";
            video_refresh_rate = "144.000000";
          };
          description = "Additional RetroArch settings (applies if services.gaming.enable is true).";
          type = with lib.types; attrsOf str;
        };
      };
    };
  };

  config = lib.mkIf gamingCfg.enable {
    # General Gaming Configuration
    programs.gamemode.enable = true;

    # Combined System Packages
    environment.systemPackages = with pkgs; [
      # General Gaming Packages (excluding Steam and emulators)
      lutris
      wine
      dxvk
      vkbasalt
      pingus
      hedgewars
      sunshine
      evtest
      oversteer
      linuxConsoleTools
      gamepad-tool
      qjoypad
      wineWowPackages.full
      winetricks
      torzu
    ];
  };
}








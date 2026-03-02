{ config, pkgs, lib, ... }:

let
  gamingCfg = config.services.gaming;
  emulatorsSpecificCfg = gamingCfg.emulators;
in
{
  imports = [
    ./roms.nix
  ];
  # options = { services.gaming.emulators = { ... }; }; # Options are defined in default.nix

  config = lib.mkIf gamingCfg.enable {
    nixpkgs.config = {
      permittedInsecurePackages = [
        "freeimage-unstable-2021-11-01" # for emulationstation-de
      ];
    };

    environment.systemPackages =
      let
        defaultEmulatorPackages = with pkgs; [
          emulationstation-de
          mame
          (wrapRetroArch {
            cores = with pkgs.libretro;
              [
                beetle-pce # pcenginecd
                beetle-pce-fast # pcenginecd
                beetle-wswan # wonderswan
                bsnes # snes
                fceumm # nes
                gambatte # gb, gbc
                genesis-plus-gx # genesis
                mesen # nes
                mesen-s # snes
                mgba # gba
                sameboy # gb, gbc
                snes9x # snes
                beetle-psx-hw # psx
                beetle-saturn # saturn
                melonds # nds
                mupen64plus # n64
                parallel-n64 # n64
                flycast # dreamcast
                dolphin # gc, wii
              ] ++
              (lib.optionals emulatorsSpecificCfg.pc [
                bluemsx # msx
                dosbox # dos
                dosbox-pure # dos
                fmsx # msx
                np2kai # pc98
                puae # amiga
              ]);
            settings = {
              assets_directory = "${pkgs.retroarch-assets}/share/retroarch/assets";
              joypad_autoconfig_dir = "${pkgs.retroarch-joypad-autoconfig}/share/libretro/autoconfig";
              libretro_info_path = "${pkgs.libretro-core-info}/share/retroarch/cores";
              content_runtime_log_aggregate = "true";
              gamemode_enable = if config.programs.gamemode.enable then "true" else "false";
              input_max_users = "2";
              quit_on_close_content = "2"; # CLI
              video_fullscreen = "true";
              menu_driver = "xmb";
              menu_shader_pipeline = "2";
              menu_swap_ok_cancel_buttons = "true"; # Non-Japanese
              ozone_menu_color_theme = "12";
              xmb_menu_color_theme = "1";
              cheevos_enable = "true";
              cheevos_hardcore_mode_enable = "true";
            } // emulatorsSpecificCfg.retroarchExtraConfig;
          })
          duckstation # psx
          melonDS # nds
          ppsspp # psp
          flycast # dreamcast
          pcsx2 # ps2
          xemu # xbox
          rpcs3 # ps3
          dolphin-emu # gc, wii
        ];

        pcSpecificStandalonePackages = lib.optionals emulatorsSpecificCfg.pc (with pkgs; [
          _86Box-with-roms
          # (pkgs.callPackage ../packages/quasi88.nix {})
        ]);

      in
      defaultEmulatorPackages ++ pcSpecificStandalonePackages;
  };
}

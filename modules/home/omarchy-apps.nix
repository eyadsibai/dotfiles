# Omarchy preinstalls that nixarchy doesn't carry: Hype, Monologue, Signed,
# disktree and Superwhisper, packaged in pkgs/. Imported by modules/nixos/desktop.nix.
{ lib, pkgs, ... }:
let
  omacom = pkgs.callPackage ../../pkgs/omacom-apps.nix { };
  disktree = pkgs.callPackage ../../pkgs/disktree.nix { };
  superwhisper = pkgs.callPackage ../../pkgs/superwhisper { };
in
{
  home.packages = [
    omacom.hype
    omacom.monologue
    omacom.signed
    disktree
    superwhisper
  ];

  # Superwhisper's daemon, as its Arch package installs it; Omarchy's dictation
  # keys reach it through omarchy-dictation-superwhisper. Not started with the
  # session while it's unlicensed (Voxtype dictates meanwhile); add
  # `Install.WantedBy = [ "graphical-session.target" ];` once it has a licence
  systemd.user.services.superwhisper = {
    Unit = {
      Description = "Superwhisper dictation";
      After = [
        "graphical-session.target"
        "pipewire.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe superwhisper} daemon";
      ExecStopPost = "${lib.getExe superwhisper} playback-restore";
      Restart = "on-failure";
      RestartSec = 2;
      KillMode = "control-group";
      TimeoutStopSec = 15;
      UMask = "0077";
    };
  };

  # The rest of Omarchy's setup-user: its bar panel, and the payload where the
  # portable install keeps it
  xdg.configFile."omarchy/plugins/superwhisper-panel".source =
    "${superwhisper}/opt/superwhisper/assets/omarchy-plugin/superwhisper-panel";
  xdg.dataFile."superwhisper/app/current".source = "${superwhisper}/opt/superwhisper";

  # A fresh profile records with Alt+Space: upstream's Right Alt hold conflicts
  # with Omarchy's bindings. Seeded once; the settings app owns it afterwards.
  home.activation.superwhisperPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    prefs="''${XDG_CONFIG_HOME:-$HOME/.config}/superwhisper/preferences.json"
    if [[ ! -e $prefs && ! -v DRY_RUN ]]; then
      mkdir -p "''${prefs%/*}"
      (umask 077; printf '%s\n' '{"toggleRecordingShortcut":"Alt+Space","pushToTalkShortcut":"","cancelRecordingShortcut":"Escape"}' > "$prefs")
    fi
  '';
}

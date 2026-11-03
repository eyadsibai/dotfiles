# herdr, the terminal workspace manager for AI coding agents, with keys mirroring
# Omarchy's tmux config. The config is linked from this directory, so herdr's own
# edits and `prefix+q` reloads work on the repo copy. On NixOS nixarchy installs
# herdr itself (with its bar widget); the Macs get it here. The Arch machines keep
# their own herdr config in files/host-<name>.
{
  config,
  lib,
  pkgs,
  repoDir,
  isArch,
  ...
}:
{
  home.packages = lib.optional pkgs.stdenv.hostPlatform.isDarwin pkgs.herdr;

  xdg.configFile."herdr/config.toml" = lib.mkIf (!isArch) {
    source = config.lib.file.mkOutOfStoreSymlink "${repoDir}/modules/home/herdr/config.toml";
  };
}

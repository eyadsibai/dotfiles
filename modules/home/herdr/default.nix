# herdr, the terminal workspace manager for AI coding agents, with keys mirroring
# Omarchy's tmux config. Every host shares the one config in files/herdr/, linked
# straight to the checkout so herdr's own edits and `prefix+q` reloads land in git.
# On NixOS nixarchy installs herdr itself (with its bar widget); the Macs get it here.
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
    source = config.lib.file.mkOutOfStoreSymlink "${repoDir}/files/herdr/.config/herdr/config.toml";
  };
}

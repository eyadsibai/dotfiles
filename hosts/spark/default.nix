# NVIDIA DGX Spark (GB10, arm64), on the Ubuntu NVIDIA ships it with: where the models
# run, reached over ssh. Home Manager only. Ubuntu owns the system; apt has few of the
# CLI tools and old ones, so unlike on the Arch machines Nix installs the programs here.
# What apt still has to install (drivers, services, libraries, vendors' desktop apps) is
# apt/spark.packages; a switch points out anything both have (scripts/apt-packages).
{ pkgs, ... }:
{
  # The shared set (modules/home/default.nix) without what needs a desk in front of it:
  # no mpv, no newsboat
  imports = [
    ../../modules/home/cli.nix
    ../../modules/home/shell.nix
    ../../modules/home/dev.nix
    ../../modules/home/onepassword.nix
    ../../modules/home/ssh.nix
    ../../modules/home/home-lan.nix
    ../../modules/home/transfer.nix
    ../../modules/home/herdr
    ../../modules/home/files.nix
  ];

  my.files = [ "host-spark" ];

  # Programs that were apt's here and are Nix's now, beyond the shared set
  # (uv and nodejs come from modules/home/dev.nix)
  home.packages = [
    pkgs.xclip # micro's clipboard
  ];

  # Ubuntu owns the GPU drivers and the MIME database, and nothing Nix installs here
  # draws with the GPU. Left on, the first has every switch warn until sudo links
  # Nix's drivers into /run, and the second puts Nix's MIME types ahead of GNOME's.
  targets.genericLinux.gpu.enable = false;
  xdg.mime.enable = false;

  # No 1Password app here to start at login: keys arrive through a forwarded agent
  xdg.configFile."autostart/1password.desktop".enable = false;

  # ~/.bashrc and ~/.profile are Home Manager's now, so what installers had appended
  # to Ubuntu's goes here: NVIDIA AI Workbench's `nvwb`, which is a shell function,
  # and ~/.local/bin, where uv, Claude Code, herdr and hf put themselves.
  programs.bash.initExtra = ''
    [[ -r ~/.local/share/nvwb/nvwb-wrapper.sh ]] && source ~/.local/share/nvwb/nvwb-wrapper.sh
  '';
  home.sessionPath = [ "$HOME/.local/bin" ];

  home.stateVersion = "26.05";
}

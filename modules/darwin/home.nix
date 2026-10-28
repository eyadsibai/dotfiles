# Home Manager settings only the Macs use
{ pkgs, ... }:
{
  programs.zsh.initContent = ''
    export PATH="$HOME/.local/bin:$PATH"

    if [[ $(uname -m) == 'arm64' ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  '';

  programs.git.includes = [
    {
      path = "~/dev/.gitconfig";
      condition = "gitdir:~/dev/";
    }
  ];

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options.features = "side-by-side";
  };

  programs.yazi = {
    enable = true;
    shellWrapperName = "y"; # the new default; silences the warning
  };
  programs.lazygit.enable = true;
  programs.zoxide.enable = true;
  programs.bun.enable = true;
  programs.yt-dlp.enable = true;
  programs.lapce.enable = true;
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      recolor = true;
      window-title-home-tilde = true;
      statusbar-basename = true;
      statusbar-h-padding = 0;
      statusbar-v-padding = 0;
      page-padding = 1;
    };
    mappings = {
      f = "toggle_fullscreen";
      w = "adjust_window width";
      n = "navigate next";
      b = "navigate previous";
      "<Space>" = "toggle_statusbar";
      u = "scroll half-up";
      d = "scroll half-down";
      D = "toggle_page_mode";
      r = "reload";
      R = "rotate";
      K = "zoom in";
      J = "zoom out";
      i = "recolor";
      p = "print";
    };
  };
  programs.kakoune.enable = true;
  programs.bat.enable = true;

  programs.gpg = {
    enable = true;
    settings = {
      trust-model = "tofu+pgp";
      throw-keyids = false;
      no-emit-version = true;
      no-comments = true;
    };
    scdaemonSettings.disable-ccid = true;
  };
}

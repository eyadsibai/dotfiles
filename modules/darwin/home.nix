# Home Manager settings only the Macs use
{
  lib,
  osConfig,
  ...
}:
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

  programs.yazi = {
    enable = true;
    shellWrapperName = "y"; # the new default; silences the warning
  };
  programs.lazygit.enable = true;
  programs.zoxide.enable = true;
  programs.lapce.enable = true;
  # Homebrew installs zathura (homebrew.nix); this only writes its config
  programs.zathura = {
    enable = true;
    package = null;
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
  # Homebrew's zathura looks for plugins only in its own lib/zathura, which the tap
  # leaves to be filled by hand and an upgrade of zathura empties again. Home Manager
  # activates after Homebrew has run, so what it just installed is there to link.
  home.activation.zathuraPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    zathura=${osConfig.homebrew.prefix}/opt/zathura
    if [[ -d $zathura ]]; then
      run mkdir -p "$zathura/lib/zathura"
      for plugin in ${osConfig.homebrew.prefix}/opt/zathura-*/lib*.dylib; do
        if [[ -f $plugin ]]; then
          run ln -sf $VERBOSE_ARG "$plugin" "$zathura/lib/zathura/"
        fi
      done
    fi
  '';

  programs.kakoune.enable = true;

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

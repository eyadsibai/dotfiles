# On Arch these come from pacman (arch/<host>.packages) and only the config is set
# here; everywhere else Nix installs them too.
{
  lib,
  pkgs,
  isArch,
  ...
}:
let
  nnn = {
    bookmarks = {
      D = "~/Downloads";
      p = "~/dev";
      c = "~/.config";
    };
    src =
      (pkgs.fetchFromGitHub {
        owner = "jarun";
        repo = "nnn";
        rev = "v4.9";
        sha256 = "sha256-g19uI36HyzTF2YUQKFP4DE2ZBsArGryVHhX79Y0XzhU=";
      })
      + "/plugins";
    mappings = {
      p = "preview-tui";
      o = "fzopen";
    };
  };
  # NNN_BMS / NNN_PLUG format, as the nnn module writes it: key:value;key:value
  nnnList = attrs: lib.concatStringsSep ";" (lib.mapAttrsToList (k: v: "${k}:${v}") attrs);
in
{
  # cachix isn't packaged for Arch, so Nix installs it everywhere
  home.packages = [
    pkgs.cachix
  ]
  ++ lib.optionals (!isArch) (
    with pkgs;
    [
      micro
      tmux
      just
      gum
      timg # images in the terminal

      # archives
      zip
      xz
      unzip
      p7zip
      zstd

      # search & data
      ripgrep
      jq
      yq-go

      # storage & cloud
      rclone
      ncdu
      awscli2

      # network
      socat
      nmap
      caddy

      # misc
      cowsay
      file
      which
      tree
      gnused
      gnutar
      gawk
      glow # markdown viewer
    ]
  );

  # Omarchy's own shell init already loads pacman's fzf key bindings on Arch
  programs.fzf.enable = !isArch;

  programs.bat = {
    enable = true;
    # pacman's bat (Omarchy ships it), seen through a link so the module has a package
    package = lib.mkIf isArch (
      import ./pacman-bin.nix pkgs {
        bin = "bat";
        from = pkgs.bat;
      }
    );
  };

  programs.eza = {
    enable = true;
    package = lib.mkIf isArch null;
    git = true;
    icons = "auto";
  };

  programs.btop = {
    enable = true;
    package = lib.mkIf isArch null;
    settings.proc_sorting = "cpu direct";
  };

  # The module reads skim's key bindings from its own package; on Arch they're
  # sourced from pacman's skim instead (below)
  programs.skim = {
    enable = !isArch;
    enableBashIntegration = true;
  };

  # The module wraps its own nnn; on Arch the same settings are set up by hand below
  programs.nnn = {
    enable = !isArch;
    inherit (nnn) bookmarks;
    plugins = {
      inherit (nnn) src mappings;
    };
  };

  # On Arch: pacman's skim and nnn, with the settings the modules above would apply
  programs.bash.initExtra = lib.mkIf isArch ''
    [[ -r /usr/share/skim/key-bindings.bash ]] && source /usr/share/skim/key-bindings.bash
  '';
  home.sessionVariables = {
    # man pages through bat (above): colours, and its pager's search
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
    # ripgrep doesn't read ~/.ripgreprc unless told where it lives
    RIPGREP_CONFIG_PATH = "$HOME/.ripgreprc";
  }
  // lib.optionalAttrs isArch {
    NNN_BMS = nnnList nnn.bookmarks;
    NNN_PLUG = nnnList nnn.mappings;
  };
  home.file = {
    ".ripgreprc".text = ''
      --smart-case
      --hidden
      --follow
      --glob=!.git/
      --glob=!node_modules/
      --glob=!.venv/
      --glob=!__pycache__/
      --glob=!target/
      --glob=!dist/
      --glob=!.next/
      --max-columns=200
      --max-columns-preview
    '';
    ".fdignore".text = ''
      .git/
      node_modules/
      .venv/
      __pycache__/
      target/
      dist/
      .next/
      .cache/
      .gradle/
      build/
      .DS_Store
      *.pyc
    '';
    ".inputrc".text = ''
      set completion-ignore-case on
      set completion-prefix-display-length 2
      set show-all-if-ambiguous on
      set show-all-if-unmodified on

      # Arrow keys match what you've typed so far against your command history
      "\e[A": history-search-backward
      "\e[B": history-search-forward
      "\e[C": forward-char
      "\e[D": backward-char

      # Immediately add a trailing slash when autocompleting symlinks to directories
      set mark-symlinked-directories on

      # Do not autocomplete hidden files unless the pattern explicitly begins with a dot
      set match-hidden-files off

      # Show all autocomplete results at once
      set page-completions off

      # If there are more than 200 possible completions for a word, ask to show them all
      set completion-query-items 200

      # Show extra file information when completing, like `ls -F` does
      set visible-stats on

      # Look at text after the cursor when completing (Readline in Bash 4+)
      set skip-completed-text on

      # Coloring for Bash 4 tab completions.
      set colored-stats on
    '';
  };
  xdg.configFile."nnn/plugins" = lib.mkIf isArch { source = nnn.src; };

  programs.aria2 = {
    enable = true;
    package = lib.mkIf isArch null;
    settings = {
      max-connection-per-server = 4;
      split = 4;
      min-split-size = "1M";
      disk-cache = "64M";
      file-allocation = "falloc";
      continue = true;
      max-concurrent-downloads = 5;
    };
  };
}

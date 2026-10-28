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
  programs.zathura.enable = true;
  programs.kakoune.enable = true;
  programs.bat.enable = true;
  programs.fzf.enable = true;

  programs.mpv = {
    enable = true;
    config = {
      profile = "high-quality"; # formerly gpu-hq
      force-window = true;
      ytdl-format = "bestvideo+bestaudio";
      demuxer-max-bytes = "4000MiB"; # replaces the removed cache-default
    };
  };

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

{ ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # bashrcExtra = ''
    #   export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
    # '';
  };

  programs.bash = {
    enable = true;
    # shellInit = ''
    #   eval "$(direnv hook bash)"
    #   '';

  };



  programs.nushell = {
    enable = true;
  };

  # home.shellAliases = {
  #   k = "kubectl";

  #   urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
  #   urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
  # };

  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  programs.zellij = {
    enable = true;

  };
}

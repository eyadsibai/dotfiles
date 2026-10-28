# SSH client defaults for every host (the 1Password agent is set in onepassword.nix)
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # Omarchy's keepalive: notice a dead connection within ~45 s instead of hanging,
    # and give up on unreachable hosts after 10 s
    settings."Host *" = {
      ServerAliveInterval = 15;
      ServerAliveCountMax = 3;
      ConnectTimeout = 10;
    };
  };
}

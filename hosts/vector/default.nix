# Dell XPS 14 (2026), Omarchy on Arch: the laptop I carry. Home Manager only.
{
  my.files = [ "host-vector" ];

  # My own machines, reached from here over Tailscale; they get this laptop's 1Password
  # agent, named because `ForwardAgent yes` would forward gnome-keyring's instead
  programs.ssh.settings = {
    "Host cachy" = {
      HostName = "cachy";
      ForwardAgent = "~/.1password/agent.sock";
    };
    "Host desktop" = {
      HostName = "desktop";
      User = "eyada";
      ForwardAgent = "~/.1password/agent.sock";
    };
  };
  home.stateVersion = "26.05";
}

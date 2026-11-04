# Dell XPS 14 (2026), Omarchy on Arch: the laptop I carry. Home Manager only.
{
  my.files = [ "host-vector" ];

  # My own machines, reached from here over Tailscale; they get this laptop's agent
  programs.ssh.settings = {
    "Host cachy" = {
      HostName = "cachy";
      ForwardAgent = "yes";
    };
    "Host desktop" = {
      HostName = "desktop";
      User = "eyada";
      ForwardAgent = "yes";
    };
  };
  home.stateVersion = "26.05";
}

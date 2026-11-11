# Home Manager configuration for the main user
{
  imports = [
    ./cli.nix
    ./shell.nix
    ./dev.nix
    ./onepassword.nix
    ./ssh.nix
    ./transfer.nix
    ./herdr
    ./newsboat
    ./mpv
  ];
}

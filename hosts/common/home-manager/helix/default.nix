{ pkgs, ... }:
{
  programs.helix = {
    enable = true;
    languages = [
      {
        auto-format = false;
        name = "rust";
      }
      { name = "python"; }
      { name = "nix"; auto-format = true; }
    ];
  };
}

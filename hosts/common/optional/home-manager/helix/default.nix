{ pkgs, ... }: {
  programs.helix = {
    enable = true;
    languages = [
      {
        auto-format = false;
        name = "rust";
      }
      o99
      { name = "python"; }
      {
        name = "nix";
        auto-format = true;
      }
    ];
  };
}

{ pkgs, ... }: {
  programs.helix = {
    enable = true;
    languages = [
      {
        auto-format = false;
        name = "rust";
      }
      {
        name = "haskell";
        auto-format = true;
      }

      { name = "python"; }
      {
        name = "nix";
        auto-format = true;
      }
    ];
  };
}

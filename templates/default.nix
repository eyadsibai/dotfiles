{
  flake = {
    description = "basic flake environment template";
    path = ./flake;
  };

  flake-toml = {
    description = "flake envrionment supporting toml template";
    path = ./flake-toml;
  };

  python = {
    description = "flake for python project";
    path = ./python;
  };
}

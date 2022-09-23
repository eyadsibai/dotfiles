{
  flake = {
    description = "basic flake environment template";
    path = ./flake;
  };

  flake-toml = {
    description = "flake envrionment supporting toml template";
    path = ./flake-toml;
  };

  go = {
    description = "flake for go project";
    path = ./go;
  };

  java = {
    description = "flake for java project";
    path = ./java;
  };

  ml-python = {
    description = "flake for python project";
    path = ./ml-python;
  };

  nodejs = {
    description = "flake for nodejs project";
    path = ./nodejs;
  };

  r = {
    description = "flake fpr r project";
    path = ./r;
  };

  rust = {
    description = "flake for rust project";
    path = ./rust;
  };
}

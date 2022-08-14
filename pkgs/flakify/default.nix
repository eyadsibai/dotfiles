{ writeShellApplication, nix-direnv }: writeShellApplication {
  name = "flakify";

  runtimeInputs = [ nix-direnv ];

  text = ''
      if [ ! -e flake.nix ]; then
      nix flake new -t github:nix-community/nix-direnv .
    elif [ ! -e .envrc ]; then
      echo "use flake" > .envrc
      direnv allow
    fi
  '';
}

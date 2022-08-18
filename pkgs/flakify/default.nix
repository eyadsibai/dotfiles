{ writeShellApplication, nix-direnv }: writeShellApplication {
  name = "flakify";

  runtimeInputs = [ nix-direnv ];

  text = ''
      if [ ! -e flake.nix ]; then
      nix flake new -t github:eyadsibai/dotfiles#flake .
    elif [ ! -e .envrc ]; then
      echo "use flake" > .envrc
      direnv allow
    fi
  '';
}

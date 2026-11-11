# dl/ul copy files between a machine reached over ssh and the one you're typing on.
# The Arch machines link them from files/scripts with the rest of ~/.local/bin;
# everywhere else gets them as packages, with GNU coreutils for `realpath -m`.
{
  lib,
  pkgs,
  isArch,
  ...
}:
let
  script =
    name:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.coreutils ];
      text = builtins.readFile ../../files/scripts/.local/bin/${name};
    };
in
{
  home.packages = lib.mkIf (!isArch) (
    map script [
      "dl"
      "ul"
    ]
  );
}

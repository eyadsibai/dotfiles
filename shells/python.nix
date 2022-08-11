{
  pkgs ? import <nixpkgs> {},
  inputs,
  ...
}: let
  python = "python310";
  #  pypiDataRev = "461ca876caaa7da5e633e6629cc272fcbe5579a3";
  #  pypiDataSha256 = "16kin3j5f57cnzpz9nspk49dimxdpw2x84q3fag86947xw59pdfv";

  mach-nix-wrapper = import inputs.mach-nix {inherit pkgs python;};
  #  requirements = builtins.readFile ./requirements.txt;
  #  pythonShell = mach-nix-wrapper.mkPythonShell { inherit requirements; };
  pythonShell = mach-nix-wrapper.mkPython {
    requirements = ''
      # pandas
      black
    '';
  };
in
  pkgs.mkShell {
    buildInputs = [
      (pkgs.${python}.withPackages
        (ps: with ps; [pip pyflakes isort]))
      #  pkgs.nodePackages.pyright
      #  pkgs.nodePackages.prettier
      #  pkgs.docker
      #  pkgs.glpk
      pythonShell
    ];
    shellHook = "";
  }

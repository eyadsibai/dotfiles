{ config
, pkgs
, ...
}: {
  programs.direnv = {
    enable = true;
    nix-direnv = { enable = true; };
    enableBashIntegration = true;
    enableZshIntegration = true;
    # enableFishIntegration = false;
    stdlib = ''
              layout_anaconda() {

            # Detect environment name from `environment.yml` file in `.envrc` directory
            source activate `grep name: environment.yml | sed -e ‘s/name: //’ | cut -d “‘“ -f 2 | cut -d ‘“‘ -f 2`
            else
            (>&2 echo No environment specified);
            exit 1;
      }
    '';
    config = {
      global = { warn_timeout = "1m"; };
    };
  };
}

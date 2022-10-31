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
      #     layout_anaconda() {
      #       local ACTIVATE="${config.home.homeDirectory}/.conda/bin/activate"

      #   if [ -n "$1" ]; then
      #     # Explicit environment name from layout command.
      #     local env_name="$1"
      #     source $ACTIVATE \$\{env_name\}
      #   elif (grep -q name: environment.yml); then
      #     # Detect environment name from `environment.yml` file in `.envrc` directory
      #     source $ACTIVATE `grep name: environment.yml | sed -e 's/name: //' | cut -d "'" -f 2 | cut -d '"' -f 2`
      #   else
      #     (>&2 echo No environment specified);
      #     exit 1;
      #   fi;
      # }
    '';
    config = {
      global = { warn_timeout = "1m"; };
    };
  };
}

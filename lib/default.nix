{ inputs, ... }: let inherit (inputs) self nixpkgs;inherit (self) outputs; in rec { }

#https://github.com/archseer/snowflake/blob/master/lib/utils.nix can I move mergeEnvs here?

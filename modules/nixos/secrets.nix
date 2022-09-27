{ lib, ... }:
let
  inherit (lib) types mkOption;
  secrets = import ../../secrets;
in
{
  options.secrets = mkOption {
    type = types.attrsOf (types.attrsOf (types.attrsOf (types.either (types.either types.int types.str) (types.functionTo types.str))));
    default = { };
  };
  config.secrets = secrets;
}

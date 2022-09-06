{ lib, config, ... }:

let
  mkFontOption = kind: {
    family = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = "Family name for ${kind} font profile";
      example = "Fira Code";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = null;
      description = "Package for ${kind} font profile";
      example = "pkgs.fira-code";
    };
  };
  cfg = config.fontProfiles;
in
{
  options.fontProfiles = {
    enable = lib.mkEnableOption "Whether to enable font profiles";
    monospace = mkFontOption "monospace";
    regular = mkFontOption "regular";
    # weather-icons = mkFontOption "weather-icons";
    # material-design-icons = mkFontOption "material-design-icons";
    # material-icons = mkFontOption "material-icons";
  };


  config = lib.mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    home.packages = [
      cfg.monospace.package
      cfg.regular.package
      # cfg.weather-icons.package
      # cfg.material-design-icons.package
      # cfg.material-icons.package
    ];
  };
}

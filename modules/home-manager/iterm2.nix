{ config, lib, pkgs, ... }:

with lib;

let
  enabled = cfg.enable && pkgs.hostPlatform.isDarwin;
  cfg = config.programs.iterm2;

  shell_integration = pkgs.fetchFromGitHub {
    name = "iterm2-shell-integration";
    owner = "gnachman";
    repo = "iTerm2-shell-integration";
    rev = "891c1aa5fd8ecfebd953d85c6994f3ee8f0d8f3c";
    sha256 = "sha256-d5RrXxmvNJLGrutu1p2t9Gd6qwFn0uUlOKby5C7oVmc=";
  };
  utilities = builtins.attrNames (builtins.readDir "${shell_integration}/utilities");
  aliases = lib.concatMapStringsSep ";" (x: "alias ${x}='${shell_integration}/utilities/${x}'") utilities;

in
{
  options.programs.iterm2 = {
    enable = mkEnableOption "iterm2";

    package = mkOption {
      type = types.package;
      default = pkgs.iterm2;
      defaultText = literalExpression "pkgs.iterm2";
      description = "The package to use for iterm2";
    };

    profiles = mkOption {
      type = with types;
        let
          prim = oneOf [ bool int str float ];
          primOrPrimAttrs = either prim (attrsOf prim);
          entry = either prim (listOf primOrPrimAttrs);
          entryOrAttrsOf = t: either entry (attrsOf t);
          entries = entryOrAttrsOf (entryOrAttrsOf entry);
        in
        listOf (attrsOf entries) // { description = "iterm2 profiles"; };
      default = [ ];
      example = literalExpression ''
        [
          {
            Name = "home-manager profile";
            Guid = "02F712C4-2AF1-4236-98BB-3F44FD753723";
            "Unlimited Scrollback" = true;
          }
          {
            Name = "foo.example.com";
            Guid = "foo.example.com";
            "Custom Command" = "Yes";
            Command = "ssh foo.example.com";
          }
        ]
      '';
      description = ''
        iTerm2 profiles to be linked into the DynamicProfiles directory
        See https://iterm2.com/documentation-dynamic-profiles.html for usage examples
      '';
    };
    preferences = mkOption {
      type = with types;
        let
          prim = oneOf [ bool int str float ];
          primOrPrimAttrs = either prim (attrsOf prim);
          entry = either prim (listOf primOrPrimAttrs);
          entryOrAttrsOf = t: either entry (attrsOf t);
          entries = entryOrAttrsOf (entryOrAttrsOf entry);
        in
        attrsOf entries // { description = "iterm2 preferences"; };
      default = { };
      example = literalExpression ''
        {
          "Default Bookmark Guid" = "02F712C4-2AF1-4236-98BB-3F44FD753723";
          PromptOnQuit = false;
          SoundForEsc = false;
        }
      '';
      description = ''
        iTerm2 preferences to be linked into ~/.config/iterm2
        To be used, will need to set "Load preferences from a custom folder or URL" in General->Preferences to this folder
      '';
    };
  };

  config = mkIf cfg.enable {


    home.packages = [ cfg.package ];

    # Initialise Shell Integration
    programs.bash.initExtra = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/bash" || true
      ${aliases}
    '';
    programs.fish.interactiveShellInit = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/fish"; or true
      ${aliases}
    '';
    programs.zsh.initExtra = ''
      # Initialise iTerm2 integration
      source "${shell_integration}/shell_integration/zsh" || true
      ${aliases}
    '';


    # If a profile is specified, add it to the DynamicProfiles folder
    xdg.configFile."iterm2/AppSupport/DynamicProfiles/home-manager.plist" = mkIf (cfg.profiles != [ ]) {
      text = toPlist { Profiles = cfg.profiles; };
    };

    # If preferences are specified, add them to .config/iterm2
    xdg.configFile."iterm2/com.googlecode.iterm2.plist" = mkIf (cfg.preferences != { }) {
      text = toPlist cfg.preferences;
    };
  };

}

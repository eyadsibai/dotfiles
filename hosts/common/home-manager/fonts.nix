{ inputs
, lib
, pkgs
, config
, outputs
, ...
}: {
  home.packages = with pkgs; [
    (nerdfonts.override
      {
        fonts = [ "Terminus" ];
      })
  ];

  fontProfiles = {
    enable = true;
    monospace = {
      family = "FiraCode Nerd Font Mono";
      package = pkgs.nerdfonts.override {
        fonts = [ "FiraCode" ];
      };
    };
    regular = {
      family = "Fira Sans";
      package = pkgs.fira;
    };
  };
}

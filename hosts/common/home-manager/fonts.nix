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
    termsyn
    tamsyn
    fantasque-sans-mono
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
    # weather-icons = {
    #   family = "Weather Icons";
    #   package = pkgs.weather-icons;
    # };
    # waffle-siji-icons {
    #   family = "waffle";
    #   package = pkgs.waffle-siji;
    # };
    # icomoon-feather-icons = {
    #   family = "feather";
    #   package = pkgs.
    # };
    # material-icons = {
    #   family = "";
    #   package = pkgs.material-icons;
    # };

    # material-design-icons = {
    #   family = "";
    #   package = pkgs.material-design-icons;
    # };
  };

}

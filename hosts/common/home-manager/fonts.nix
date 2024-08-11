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


}

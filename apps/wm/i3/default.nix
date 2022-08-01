{ pkgs, ... }: {
  imports = [ ./picom.nix ./polybar.nix ./packages.nix ./i3.nix 
  #./gtk.nix 
  ];

}

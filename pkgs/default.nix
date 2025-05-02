# Custom packages defined for this flake configuration.
# These packages are accessible via outputs.packages.${system}
{ inputs, pkgs, ... }:

let
  # Helper to call packages within this directory.
  # It automatically passes pkgs and inputs down if needed by the package definition.
  callLocalPackage = path: pkgs.callPackage path { inherit inputs pkgs; };

in
{
  # --- General Utilities ---
  flakify = callLocalPackage ./flakify;
  linkhandler = callLocalPackage ./linkhandler;
  shellcolord = callLocalPackage ./shellcolord;
  # sherlock = callLocalPackage ./sherlock; # Directory ./sherlock does not exist

  # --- Fonts ---
  apple-color-emoji = callLocalPackage ./apple-color-emoji;
  icomoon-feather-ttf = callLocalPackage ./icomoon-feather-ttf;
  waffle-font = callLocalPackage ./waffle-font; # Added from directory structure

  # --- Theming & Appearance ---
  wallpapers = callLocalPackage ./wallpapers;
  powermenu = callLocalPackage ./powermenu; # Added from directory structure

  # --- Rofi Utilities ---
  rofi-files = callLocalPackage ./rofi-files; # Added from directory structure
  rofi-monitor = callLocalPackage ./rofi-monitor; # Added from directory structure
  rofi-wifi = callLocalPackage ./rofi-wifi; # Added from directory structure

  # --- Development / Data ---
  kepler = callLocalPackage ./kepler;
  # Assuming datahub.nix defines a package function callable with callPackage
  datahub = callLocalPackage ./datahub.nix; # Added from file structure

  # --- ML Libraries ---
  rgf = callLocalPackage ./rgf;
  fast-rgf = callLocalPackage ./fast-rgf;
  libfm = callLocalPackage ./libfm;

  # --- Overrides / Specific Versions ---
  # Example: Using a specific version of caprine built from AppImage source within nixpkgs input.
  latest-caprine = pkgs.callPackage "${inputs.nixpkgs}/pkgs/applications/networking/instant-messengers/caprine-bin/build-from-appimage.nix" {
    # Overrides for the specific caprine version
    pname = "caprine";
    version = "2.56.1";
    sha256 = "sha256-NhHToaacje4TtZkW3TxtyGzH/uKGCWgGdtvI9oSTJF4=";
    # Note: Ensure this build-from-appimage.nix script is compatible with callPackage
    # and receives necessary arguments if any (like fetchurl, appimageTools etc.)
    # It might require pkgs passed explicitly if it doesn't get them implicitly.
    # If issues arise, consider passing pkgs: inherit pkgs;
  };
}

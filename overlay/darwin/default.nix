# This file defines two overlays and composes them
{ inputs
, lib
, nixConfig
, ...
}:
let

  # modifications =
  #   final:
  #   prev:
  #   {
  # yabai =
  #   prev.yabai.overrideAttrs
  #     (
  #       oldAttrs:
  #       rec {
  #         version = "4.0.1";
  #         src =
  #           prev.fetchFromGitHub
  #             {
  #               owner = "koekeishiya";
  #               repo = "${ oldAttrs.pname }";
  #               rev = "v${version}";
  #               # sha256 = prev.lib.fakeSha256;
  #               sha256 = "sha256-SSXm9o2w0YOpr1VsNm0kAuW1hsOzlmzqnpSQGJ2RH8E=";
  #             };
  #       }
  #     );
  # };
  # This one brings our custom packages from the 'pkgs' directory
  # additions = final: _prev: import ../pkgs { pkgs = final; };
  apple-silicon = self: super: (inputs.nixpkgs.lib.optionalAttrs
    (super.stdenv.system == "aarch64-darwin")
    {
      inherit (import inputs.nixpkgs
        {
          system = "x86_64-darwin";
          config = nixConfig;
        })
        idris2
        nix-index
        ;
    });

in
inputs.nixpkgs.lib.composeManyExtensions [ apple-silicon ]

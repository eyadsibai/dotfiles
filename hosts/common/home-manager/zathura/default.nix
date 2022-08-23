{ inputs
, pkgs
, config
, ...
}:

{
  # TODO https://github.com/LukeSmithxyz/voidrice/blob/master/.config/zathura/zathurarc
  programs.zathura = {
    enable = true;
    package = pkgs.stable.zathura;
    #   extraConfig =
    #     builtins.readFile (config.scheme inputs.base16-zathura);
  };
}

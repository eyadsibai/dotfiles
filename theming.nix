{ config, pkgs, inputs, ... }: {
  programs.zathura.extraConfig =
    builtins.readFile (config.scheme inputs.base16-zathura);

}

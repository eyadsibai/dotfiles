{ pkgs, ... }: {
  xdg.homeFile.".jupyter/jupyter_notebook_config.py" = ./config.py;
}

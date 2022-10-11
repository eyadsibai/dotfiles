{ pkgs, ... }: {

  # make short-pressed Ctrl behave like Escape:
  services.xcape = {
    enable = true;
    mapExpression = { Control_L = "Escape"; };
  };
}

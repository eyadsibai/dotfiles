{ pkgs, ... }: {
  # AI related packages and configurations
  environment.systemPackages = with pkgs; [
    lmstudio
  ];
}

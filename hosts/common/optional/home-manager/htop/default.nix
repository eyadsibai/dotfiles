{ pkgs, ... }: {
  programs.htop = {
    enable = true;
    settings = {
      sort_direction = false;
      sort_key = "PERCENT_CPU";
      show_program_path = true;
    };
  };
}

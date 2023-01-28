{ config
, pkgs
, lib
, username
, ...
}: {
  home-manager.users.${username} = {
    programs.kakoune.enable = true;
    programs.yt-dlp.enable = true;
    programs.gallery-dl.enable = true;
    home.enableNixpkgsReleaseCheck = true;


    xdg.configFile."wget/wgetrc".text = ''
      hsts-file=~/.cache/wget-hsts
    '';

    xdg.configFile."pudb/pudb.cfg".text = ''
      [pudb]
        breakpoints_weight = 1
        current_stack_frame = top
        custom_shell =
        custom_stringifier =
        custom_theme =
        default_variables_access_level = public
        display = auto
        hide_cmdline_win = False
        line_numbers = True
        prompt_on_quit = True
        seen_welcome = e039
        shell = ipython
        sidebar_width = 0.5
        stack_weight = 1
        stringifier = type
        theme = midnight
        variables_weight = 1
        wrap_variables = True
    '';

  };
}

{ pkgs
, lib
, config
, ...
}: {
  programs.bash = {
    enable = true;
    initExtra = "neofetch";
    historyIgnore = [ "exit" "tree" ];
  };

  programs.fish = {
    enable = true;
    shellAbbrs = {
      # ls = "exa";
      cat = "bat";
      top = "btm";

      jqless = "jq -C | less -r";

      n = "nix";
      nd = "nix develop -c $SHELL";
      ns = "nix shell";
      nb = "nix build";
      nf = "nix flake";

      nr = "nixos-rebuild --flake .";
      dr = "darwin-rebuild --flake .";
      nrs = "nixos-rebuild --flake . switch";
      sdrs = "sudo darwin-rebuild --flake . switch";
      snr = "sudo nixos-rebuild --flake .";
      snrs = "sudo nixos-rebuild --flake . switch";
      hm = "home-manager --flake .";
      hms = "home-manager --flake . switch";

      v = "nvim";
      vi = "nvim";
      vim = "nvim";
      m = "neomutt";
      mutt = "neomutt";
    };
    shellAliases = {
      # Get ip
      getip = "curl ifconfig.me";
      # SSH with kitty terminfo
      kssh = "kitty +kitten ssh";
      # Clear screen and scrollback
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";

      show_wifi_passwords = "sudo bash -c \"cat /etc/NetworkManager/system-connections/* | grep -e id= -e psk= -e wep | grep -v uuid= | grep -v ssid=\"";

      xclip = "xclip -selection -c";
      conda_export = "conda env export --no-builds | grep -v \"^prefix: \" > environment.yml";

      # ls = "ls --color=auto -a";
      # ll = "ls -alF";
      # la = "ls -A";
      l = "ls -CF";

      free = "free -m";

      df = "df -h";
      cp = "cp -i";

      # Add an "alert" alias for long running commands.  Use like so:
      #   sleep 10; alert
      # switch $status to $? for other shells
      alert = "notify-send --urgency=low -i \"$([ `$status = 0` ] && echo terminal || echo error)\" \"$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')\"";
    };
    functions = {
      fish_greeting = "${pkgs.pfetch}/bin/pfetch";
      wh = "readlink -f (which $argv)";
      fix_bin_csv = "iconv -f utf-16 -t utf-8 $1 > $2";
      gi = "wget http://www.gitignore.io/api/$argv >> .gitignore";
      mkcp = "mkdir -p `dirname $argv[2]` && cp $argv[1] $argv[2]";
      gitignore = "curl -sL https://www.gitignore.io/api/$argv";
      x = {
        body = ''
          if [ -f $argv[1] ]
            switch $argv[1]
              case "*.tar.bz2"
                tar xjf $argv[1]
              case "*.tar.gz"
                tar xzf $argv[1]
              case "*.bz2"
                bunzip2 $argv[1]
              case "*.rar"
                unrar x $argv[1]
              case "*.gz"
                gunzip $argv[1]
              case "*.tar"
                tar xf $argv[1]
              case "*.tbz2"
                tar xjf $argv[1]
              case "*.tgz"
                tar xzf $argv[1]
              case "*.zip"
                unzip $argv[1]
              case "*.Z"
                uncompress $argv[1]
              case "*.7z"
                7z x $argv[1]
              case *
                echo "'$argv[1]' cannot be extracted via x"
            end
          else
            echo "'$argv[1]' is not a valid file"
          #  fi
          end

        '';

      };
    };
    interactiveShellInit =
      # Open command buffer in vim when alt+e is pressed
      ''
        bind \ee edit_command_buffer
      ''
      + (lib.optionalString (config.programs.kitty.enable)
        # kitty integration
        ''
          set --global KITTY_INSTALLATION_DIR "${pkgs.kitty}/lib/kitty"
          set --global KITTY_SHELL_INTEGRATION enabled
          source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
          set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
        '')
      +
      # Use vim bindings and cursors
      ''
        fish_vi_key_bindings
        set fish_cursor_default     block      blink
        set fish_cursor_insert      line       blink
        set fish_cursor_replace_one underscore blink
        set fish_cursor_visual      block
      ''
      +
      # Use terminal colors
      ''
        set -U fish_color_autosuggestion      brblack
        set -U fish_color_cancel              -r
        set -U fish_color_command             brgreen
        set -U fish_color_comment             brmagenta
        set -U fish_color_cwd                 green
        set -U fish_color_cwd_root            red
        set -U fish_color_end                 brmagenta
        set -U fish_color_error               brred
        set -U fish_color_escape              brcyan
        set -U fish_color_history_current     --bold
        set -U fish_color_host                normal
        set -U fish_color_match               --background=brblue
        set -U fish_color_normal              normal
        set -U fish_color_operator            cyan
        set -U fish_color_param               brblue
        set -U fish_color_quote               yellow
        set -U fish_color_redirection         bryellow
        set -U fish_color_search_match        'bryellow' '--background=brblack'
        set -U fish_color_selection           'white' '--bold' '--background=brblack'
        set -U fish_color_status              red
        set -U fish_color_user                brgreen
        set -U fish_color_valid_path          --underline
        set -U fish_pager_color_completion    normal
        set -U fish_pager_color_description   yellow
        set -U fish_pager_color_prefix        'white' '--bold' '--underline'
        set -U fish_pager_color_progress      'brwhite' '--background=cyan'
      '';
  };
}

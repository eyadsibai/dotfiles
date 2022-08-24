{ pkgs
, ...
}:
{
  programs.exa = {
    # better 'ls'
    enable = true;
    enableAliases = true;
  };
}

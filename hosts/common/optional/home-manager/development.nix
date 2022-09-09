{ pkgs, ... }: {
  home.packages = with pkgs; [
    jetbrains.idea-community
    nano
    nanorc
    s3cmd
    # awscli2 # TODO crash on install
    # secure tunneling to localhost
    insomnia
    # rest client with graphql support
    beekeeper-studio
    vscode
    # earthly
    t-rec
    reviewdog
    # pgcli # modern postgres client # TODO crash on install
    mycli
    iredis
    usql
    vieb

    ## GIS
    qgis
  ];

  # programs.go = { enable = true; };
  # programs.java = { enable = true; };
  # programs.sbt = { enable = true; };
  programs.vscode = {
    enable = false;
    # extensions = with pkgs.vscode-extensions;
    # [
    # vscodevim.vim
    # yzhang.markdown-all-in-one
    # golang.go
    # ms-python.python
    # eamodio.gitlens
    # christian-kohler.path-intellisense
    # ms-vscode-remote.remote-ssh
    # ms-vsliveshare.vsliveshare
    # jnoortheen.nix-ide
    # ];
    # userSettings = { "update.channel" = "none"; };
  };
}

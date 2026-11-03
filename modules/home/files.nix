# Plain config files from files/<package>/, linked into ~ one by one like `stow
# --no-folding`: each folder mirrors $HOME, a host lists the packages it wants, and a
# later package wins over an earlier one for the same path. The links point at the
# checkout, not the store, so editing ~/.config/... edits the repo, and Omarchy's
# own tools (theme hooks, `omarchy-refresh-config`) write through to it as well.
{
  config,
  lib,
  repoDir,
  ...
}:
let
  # Repo-only files inside a package (tv's tests and docs)
  ignored = [
    "README.md"
    "ruff.toml"
    "tests"
    ".stow-local-ignore"
    ".ruff_cache"
  ];

  # Every file under dir, as paths relative to it
  walk =
    dir: prefix:
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        let
          rel = prefix + name;
        in
        if lib.elem name ignored then
          [ ]
        else if type == "directory" then
          walk (dir + "/${name}") "${rel}/"
        else
          [ rel ]
      ) (builtins.readDir dir)
    );

  link = package: rel: {
    name = rel;
    value.source = config.lib.file.mkOutOfStoreSymlink "${repoDir}/files/${package}/${rel}";
  };
in
{
  options.my.files = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [
      "hypr"
      "host-vector"
    ];
    description = "Packages under files/ to link into the home directory, in order of precedence (last wins).";
  };

  config.home.file = lib.foldl' (
    acc: package: acc // lib.listToAttrs (map (link package) (walk ../../files/${package} ""))
  ) { } config.my.files;
}

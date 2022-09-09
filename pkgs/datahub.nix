with import
  <nixpkgs>
{
  config.allowUnfree = true;
  # firefox-bin is unfree
}; let
  datahub =
    runCommand
      "datahub"
      {
        src =
          fetchurl
            {
              url = "https://github.com/datopian/data-cli/releases/download/v0.9.5/data-linux.gz";
              #sha256 = lib.fakeSha256;  # use this if you don't know hash
              sha256 = "11bdml1nkd9pgm688xmiw0j80xmyk7j2rb57qn5lckim6w7c75n8";
            };
      }
      ''
        ${gzip}/bin/gunzip -c $src > data-linux
        mkdir -p $out/bin
        cp data-linux $out/bin/
        chmod +x $out/bin/data-linux
      '';
in
buildEnv
rec {
  name = "datahub";
  paths = [ datahub ];
  buildInputs = paths;
}

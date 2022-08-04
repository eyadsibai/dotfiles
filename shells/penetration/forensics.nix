{ pkgs, ... }:
with pkgs;
mkShell {

  buildInputs = [
    afflib
    dcfldd
    ddrescue
    dislocker
    exiv2
    ext4magic
    extundelete
    foremost
    gef
    gzrt
    hivex
    ntfs3g
    ntfsprogs
    nwipe
    recoverjpeg
    safecopy
    sleuthkit
    srm
    stegseek
    testdisk
    volatility3
    wipe
    xorex
  ];
  shellHook = "";
}
    
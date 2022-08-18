{ pkgs ? import <nixpkgs> { }
, ...
}:
with pkgs;
mkShell
{
  buildInputs = [
    afflib
    capstone
    dcfldd
    ddrescue
    dislocker
    exiv2
    ext4magic
    extundelete
    foremost
    gef
    ghidra-bin
    gzrt
    hivex
    ntfs3g
    ntfsprogs
    nwipe
    p0f
    pdf-parser
    python39Packages.binwalk
    python39Packages.distorm3
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

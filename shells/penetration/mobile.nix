# Tools for working with Android/iOS devices
{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [ abootimg androguard apkeep apkleaks apktool dex2jar genymotion ghost simg2img trueseeing ];
  shellHook = "";
}

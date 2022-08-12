{ pkgs ? import <nixpkgs> { }
}:
with pkgs;
mkShell
  {
    buildInputs = [ maven jdk11 clojure leiningen clj-kondo ];
    shellHook =
      ''      export JAVA_HOME=${ pkgs.jdk11 }
                  PATH="${ pkgs.jdk11 }/bin:$PATH"
      '';
  }

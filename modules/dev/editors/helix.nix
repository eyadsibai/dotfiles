{ lib, config, pkgs, username, ... }:

let
  cfg = config.dev.editors.helix;

  # Helper for prettier formatter command
  prettier = lang: {
    command = lib.getExe pkgs.nodePackages.prettier;
    args = ["--parser" lang];
  };
  prettierLangs = map (e: { name = e; formatter = prettier e; });
  langs = ["css" "scss" "html"];

  # Helper for deno formatter command
  deno = lang: {
    command = lib.getExe pkgs.deno;
    args = ["fmt" "-" "--ext" lang];
  };

in
{
  options.dev.editors.helix = {
    enable = lib.mkEnableOption "Helix editor configuration";
  };

  config = lib.mkIf cfg.enable {
    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        programs.helix = {
          enable = true;
          # Ensure necessary packages for LSPs and formatters are available
          extraPackages = with pkgs; [
            # Formatters
            shfmt
            cmake-format
            alejandra
            dprint
            nodePackages.prettier # For prettier helper

            # Language Servers
            nodePackages.vscode-langservers-extracted # css, html, json
            bash-language-server
            clang-tools # clangd
            cmake-language-server
            deno # deno lsp
            nil # nix lsp
            nodePackages.typescript-language-server # js, ts
            basedpyright # python
            ruff # python linter/lsp
            tinymist # typst
            qt6.qtdeclarative # qmlls
            markdown-oxide # markdown (alternative)
            shellcheck # For bash diagnostics
          ];

          settings = {
            theme = "catppuccin_mocha"; # Assuming catppuccin theme is desired
            editor = {
              color-modes = true;
              completion-trigger-len = 1;
              completion-replace = true;
              cursorline = true;
              cursor-shape = {
                insert = "bar";
                normal = "block";
                select = "underline";
              };
              inline-diagnostics = {
                cursor-line = "hint";
                other-lines = "error";
              };
              line-number = "relative";
              lsp.display-inlay-hints = true;
              lsp.display-messages = true;
              statusline.center = ["position-percentage"];
              true-color = true;
              whitespace.characters = {
                newline = "↴";
                tab = "⇥";
              };
              bufferline = "always";
              text-width = 79;
              rulers = [ 80 ];
              auto-save = true;
              whitespace.render = {
                newline = "all";
                space = "none";
                nbsp = "all";
                tab = "none";
              };
              indent-guides.render = true;
            };
            keys.normal.space.u = {
              f = ":format"; # format using LSP formatter
              w = ":set whitespace.render all";
              W = ":set whitespace.render none";
            };
          };

          # Language configuration derived from Darwin config
          languages = {
            language =
              [
                {
                  name = "bash";
                  auto-format = true;
                  language-servers = [ "bash-language-server" ];
                  formatter = {
                    command = lib.getExe pkgs.shfmt;
                    args = ["-i" "2"];
                  };
                }
                {
                  name = "clojure";
                  injection-regex = "(clojure|clj|edn|boot|yuck)";
                  file-types = ["clj" "cljs" "cljc" "clje" "cljr" "cljx" "edn" "boot" "yuck"];
                  # Add clojure-lsp if needed via extraPackages
                }
                {
                  name = "cmake";
                  auto-format = true;
                  language-servers = ["cmake-language-server"];
                  formatter = {
                    command = lib.getExe pkgs.cmake-format;
                    args = ["-"];
                  };
                }
                {
                  name = "javascript";
                  auto-format = true;
                  language-servers = ["dprint" "typescript-language-server"];
                }
                {
                  name = "json";
                  language-servers = [ "vscode-json-language-server" ]; # From vscode-langservers-extracted
                  formatter = deno "json";
                }
                {
                  name = "markdown";
                  language-servers = ["dprint" "markdown-oxide"]; # Using markdown-oxide from Darwin config
                }
                {
                  name = "nix";
                  language-servers = [ "nil" ];
                  formatter = {
                    command = lib.getExe pkgs.alejandra;
                    args = [ "-q" ];
                  };
                }
                {
                  name = "python";
                  auto-format = true;
                  language-servers = [ "basedpyright" "ruff" ];
                }
                {
                  name = "qml";
                  language-servers = ["qmlls"];
                }
                {
                  name = "typescript";
                  auto-format = true;
                  language-servers = ["dprint" "typescript-language-server"];
                }
                {
                  name = "typst";
                  auto-format = true;
                  language-servers = ["tinymist"];
                }
                # Add C/C++ with clangd if needed
                { name = "c"; language-servers = [ "clangd" ]; }
                { name = "cpp"; language-servers = [ "clangd" ]; }
              ]
              ++ prettierLangs langs; # css, scss, html

            language-server = {
              # Configs for specific LSPs from Darwin config
              clangd.config.fallbackFlags = ["-std=c++2b"]; # Example, adjust as needed

              deno-lsp = {
                # command = lib.getExe pkgs.deno; # Command set by helix module
                # args = ["lsp"];
                environment.NO_COLOR = "1";
                config.deno = {
                  enable = true;
                  lint = true;
                  unstable = true;
                  suggest = {
                    completeFunctionCalls = false;
                    imports = {hosts."https://deno.land" = true;};
                  };
                  inlayHints = {
                    enumMemberValues.enabled = true;
                    functionLikeReturnTypes.enabled = true;
                    parameterNames.enabled = "all";
                    parameterTypes.enabled = true;
                    propertyDeclarationTypes.enabled = true;
                    variableTypes.enabled = true;
                  };
                };
              };

              nil = {
                # command = lib.getExe pkgs.nil; # Command set by helix module
                config.nil.formatting.command = ["${lib.getExe pkgs.alejandra}" "-q"];
              };

              tinymist = {
                # command = lib.getExe pkgs.tinymist; # Command set by helix module
                config = {
                  exportPdf = "onType";
                  # outputPath = "$root/target/$dir/$name"; # Consider if this path works on Linux
                  formatterMode = "typstyle";
                  formatterPrintWidth = 80;
                };
              };

              typescript-language-server = {
                # command = lib.getExe pkgs.nodePackages.typescript-language-server; # Command set by helix module
                # args = ["--stdio"];
                config = {
                  # Note: These might be specific to vscode-languageclient, check helix docs
                  # typescript-language-server.source = {
                  #   addMissingImports.ts = true;
                  #   fixAll.ts = true;
                  #   organizeImports.ts = true;
                  #   removeUnusedImports.ts = true;
                  #   sortImports.ts = true;
                  # };
                };
              };

              # Ruff config (if needed beyond defaults)
              # ruff = { ... };

              # CSS config (if needed beyond defaults)
              # vscode-css-language-server = { ... };
            };
          };
        };

        home = {
          file.".dprint.json".source = builtins.toFile "dprint.json" (builtins.toJSON {
            lineWidth = 80;
            typescript = {
              quoteStyle = "preferSingle";
              binaryExpression.operatorPosition = "sameLine";
            };
            json.indentWidth = 2;
            excludes = [ "**/*-lock.json" ];
            plugins = [
              "https://plugins.dprint.dev/typescript-0.93.0.wasm"
              "https://plugins.dprint.dev/json-0.19.3.wasm"
              "https://plugins.dprint.dev/markdown-0.17.8.wasm"
            ];
          });
        };
      };
    };
  };
}

{ lib, ... }:

{
  imports = [
    ./tailscale.nix
    ./n8n.nix
    # Ollama moved to modules/ai/ollama.nix
    ./tika.nix
    ./xrdp.nix
    ./pipewire.nix
    ./openssh.nix
  ];

  options.services = {
    # Options are defined in the imported files
    # e.g., services.tailscale.enable, services.pipewire.enable, etc.
  };
}

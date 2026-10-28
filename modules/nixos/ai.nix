# Small local models on the RTX 4090; larger ones run on the DGX Spark
# (Open WebUI at http://spark:8080 over Tailscale)
{ pkgs, ... }:
{
  # Ollama has no authentication: listen on all interfaces, but only open the
  # port on Tailscale so other tailnet machines (e.g. the laptop) can use it
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "0.0.0.0";
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 11434 ];
}

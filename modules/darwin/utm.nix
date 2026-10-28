# UTM virtual machines, with helper scripts for a Kali Linux guest
{ pkgs, ... }:
let
  # Determine architecture
  arch = if pkgs.stdenv.hostPlatform.isAarch64 then "arm64" else "amd64";

  # Kali ISO URL
  kaliIsoUrl = "https://cdimage.kali.org/kali-2024.3/kali-linux-2024.3-installer-${arch}.iso";

  # Setup script for Kali VM with UTM
  setupKaliUTM = pkgs.writeScriptBin "setup-kali-utm" ''
    #!${pkgs.stdenv.shell}

    set -e

    # Configuration
    ISO_DIR="$HOME/Downloads"
    ISO_FILE="kali-linux-2024.3-installer-${arch}.iso"
    ISO_PATH="$ISO_DIR/$ISO_FILE"
    UTM_TEMPLATES_DIR="$HOME/Library/Containers/com.utmapp.UTM/Data/Documents"

    echo "=== Kali Linux UTM Setup ==="
    echo "Architecture: ${arch}"
    echo ""

    # Download ISO if not present
    if [ ! -f "$ISO_PATH" ]; then
      echo "📥 Downloading Kali Linux ISO..."
      mkdir -p "$ISO_DIR"
      ${pkgs.curl}/bin/curl -L -# -o "$ISO_PATH" "${kaliIsoUrl}"
      echo "✅ Download complete!"
    else
      echo "✅ ISO already exists at $ISO_PATH"
    fi

    # Create UTM configuration guide
    cat > "$HOME/Desktop/Kali-UTM-Setup.md" << 'EOF'
    # Kali Linux UTM Setup Guide

    ## Quick Setup
    1. Open UTM (it should launch automatically)
    2. Click the "+" button to create a new VM
    3. Choose "Virtualize" (recommended for Apple Silicon) or "Emulate"
    4. Select "Linux" as the operating system

    ## Recommended Settings

    ### System
    - **Architecture**: ${arch}
    - **RAM**: 4096 MB (minimum 2048 MB)
    - **CPU Cores**: 2-4 (depending on your system)

    ### Storage
    - **Size**: 40 GB (minimum 20 GB)
    - **Type**: NVMe for best performance

    ### Display
    - **Emulated Display Card**: virtio-gpu-gl-pci (for better performance)
    - **Retina Mode**: Enabled

    ### Network
    - **Network Mode**: Shared Network
    - **Emulated Network Card**: virtio-net-pci

    ### Drives
    - **CD/DVD**: Browse to: $ISO_PATH
    - **Boot Order**: Ensure CD/DVD is first for installation

    ## Post-Installation
    After installing Kali:
    1. Shut down the VM
    2. Remove the ISO from CD/DVD drive
    3. Start the VM again

    ## Performance Tips
    - Enable hardware acceleration in UTM settings
    - Use virtio drivers for best performance
    - Allocate at least 4GB RAM for smooth operation
    EOF

    echo "📄 Setup guide created on Desktop!"
    echo ""
    echo "🚀 Launching UTM..."

    # Check if UTM is installed
    if [ ! -d "/Applications/UTM.app" ]; then
      echo "❌ UTM not found! Installing via Homebrew..."
      brew install --cask utm
    fi

    # Open UTM
    open -a UTM

    # Also open the setup guide
    open "$HOME/Desktop/Kali-UTM-Setup.md"

    echo ""
    echo "✅ Setup complete! Follow the guide on your Desktop to create the VM."
  '';

  # Quick launch script
  launchKaliUTM = pkgs.writeScriptBin "kali-utm" ''
    #!${pkgs.stdenv.shell}

    # Check if UTM is running
    if pgrep -x "UTM" > /dev/null; then
      echo "✅ UTM is already running"
    else
      echo "🚀 Launching UTM..."
      open -a UTM
    fi

    # If VM name is known, we could potentially use AppleScript to start it
    # osascript -e 'tell application "UTM" to start virtual machine "Kali Linux"' 2>/dev/null || true
  '';

  # UTM VM management helper
  utmHelper = pkgs.writeScriptBin "utm-helper" ''
    #!${pkgs.stdenv.shell}

    case "$1" in
      list)
        echo "📋 Available UTM VMs:"
        ls -la "$HOME/Library/Containers/com.utmapp.UTM/Data/Documents" 2>/dev/null | grep ".utm" || echo "No VMs found"
        ;;
      backup)
        if [ -z "$2" ]; then
          echo "Usage: utm-helper backup <vm-name>"
          exit 1
        fi
        echo "💾 Backing up VM: $2"
        VM_PATH="$HOME/Library/Containers/com.utmapp.UTM/Data/Documents/$2.utm"
        if [ -d "$VM_PATH" ]; then
          cp -r "$VM_PATH" "$HOME/Desktop/$2-backup-$(date +%Y%m%d).utm"
          echo "✅ Backup saved to Desktop"
        else
          echo "❌ VM not found"
        fi
        ;;
      *)
        echo "UTM Helper Commands:"
        echo "  utm-helper list     - List all VMs"
        echo "  utm-helper backup   - Backup a VM"
        ;;
    esac
  '';
in
{
  environment.systemPackages = [
    pkgs.qemu
    setupKaliUTM
    launchKaliUTM
    utmHelper
  ];

  # UTM itself comes from Homebrew (/Applications/UTM.app, which the scripts expect)
  homebrew.casks = [ "utm" ];

  environment.shellAliases = {
    utm = "open -a UTM";
    kali-setup = "setup-kali-utm";
    kali = "kali-utm";
    utm-list = "utm-helper list";
    utm-backup = "utm-helper backup";
    kali-iso = "curl -L -o ~/Downloads/kali-linux-${arch}.iso ${kaliIsoUrl}";
  };
}

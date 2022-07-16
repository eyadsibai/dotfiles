{
  description = "A very basic flake";

  inputs = {
  	nixpkgs.url = "nixpkgs/nixos-unstable";
  	home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
		nixos-hardware.url = github:NixOS/nixos-hardware;
  };
  
  outputs = { self, nixpkgs, home-manager, nixos-hardware, ... }: 
	let
		system = "x86_64-linux";

		pkgs = import nixpkgs {
			inherit system;
			config = { allowUnfree = true; 
			
			permittedInsecurePackages = [
				"electron-12.2.3"
			];
			};
		};

    lib = nixpkgs.lib;

		in {
				 
				nixosConfigurations = {
					eyad-nixos = lib.nixosSystem {
							inherit system pkgs;

							modules = [
						
								nixos-hardware.nixosModules.lenovo-thinkpad
								home-manager.nixosModules.home-manager
										./configuration.nix
							];

							

					};
				};
		};

}

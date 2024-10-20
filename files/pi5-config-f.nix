
{
  description = "Basic system config to run NixOS on Raspberry Pi 5";

  inputs = {
    # Pull the Nixpkgs input from unstable. 
    # TODO: Find suitable stable version? Easier to maintain?
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # TODO: Fork this, it shouldn't be that hard to maintain.
    nix-rpi5.url = "gitlab:vriska/nix-rpi5";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.rpi5 = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux"; 
      modules = [{ # SYSTEM CONFIG HERE
      
        # Enable generic bootloader?
        #boot.loader.generic-extlinux-compatible.enable = true;
        #boot.loader.generic-extlinux-compatible.copyKernels = true;
        #boot.loader.generic-extlinux-compatible.configFile = "/boot/extlinux/extlinux.conf";

        # Include the hardware configuration
        imports = [ ./hardware-configuration.nix ];

        # File systems
        fileSystems = {
          "/" = {
            device = "/dev/mmcblk0p2";
            fsType = "ext4";
          };
          "/boot" = {
            device = "/dev/mmcblk0p1";
            fsType = "vfat";
          };
        };

        # Swap configuration
        # TODO: Remember to change this size based on script options
        swapDevices = [{ device = "/dev/mmcblk0p3"; size = 2048; }];

        # Kernel from vraska's flake. 
        # TODO Fork this flake with-without flakes-compat
        boot.kernelPackages = nix_rpi5.legacyPackages.aarch64_linux.linuxPackages_rpi5;


        # Host info. You can set this however you like.
        networking.hostName = "nixberry";
        time.timeZone = "UTC";


        # Change this to "true" if you want to use user management utilities
        # (Like `passwd`, `useradd`, etc.) instead of Nix
        users.mutableUsers = false;
        # Default users:
        # REMEMBER TO CHANGE YOUR PASSWORDS!
        users.users = { 
          root = { isNormalUser = false; password = "root"; };
          user = { isNormalUser = true; password = "nixos"; };
        };


        # System packages can go here:
        environment.systemPackages = with pkgs; [
          #vim
          #htop
        ];

      }];
    };
  };

}


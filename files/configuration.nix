
{ config, pkgs, ... }:

{
  # Enable the bootloader
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.generic-extlinux-compatible.copyKernels = true;
  boot.loader.generic-extlinux-compatible.configFile = "/boot/extlinux/extlinux.conf";

  # Specify the kernel package for Raspberry Pi 5
  # TODO: Fork this, it shouldn't be that hard to maintain.
  boot.kernelPackages = (import (builtins.fetchTarball "https://gitlab.com/vriska/nix-rpi5/-/archive/main.tar.gz")).legacyPackages.aarch64-linux.linuxPackages_rpi5;

  # File systems
  fileSystems."/" = {
    device = "/dev/mmcblk0p2";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/mmcblk0p1";
    fsType = "vfat";
  };

  # Swap configuration (optional)
  swapDevices = [ { device = "/dev/mmcblk0p3"; size = 2048; } ];

  # Enable SSH for remote access
  #services.openssh.enable = true;

  # Timezone and localization
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Define users (replace with actual password hash)
  users.users.root = {
    isNormalUser = false;
    hashedPassword = "$6$hashed_root_password_here";
  };

  # Include the hardware configuration
  imports = [ ./hardware-configuration.nix ];

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    htop
  ];
}

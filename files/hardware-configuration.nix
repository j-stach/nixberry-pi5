{
  fileSystems."/" = {
    device = "/dev/mmcblk0p2";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/mmcblk0p1";
    fsType = "vfat";
  };

  # Swap partition (if needed)
  swapDevices = [ { device = "/dev/mmcblk0p3"; size = 2048; } ];

  # Required kernel modules for Raspberry Pi 5
  boot.initrd.availableKernelModules = [ "bcm2835_sdhost" "bcm2835_dma" ];
  boot.kernelModules = [ "vc4" "bcm2835_v4l2" ];

  # Bootloader configuration
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.generic-extlinux-compatible.copyKernels = true;
  boot.loader.generic-extlinux-compatible.configFile = "/boot/extlinux/extlinux.conf";
}

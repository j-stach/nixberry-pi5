
package Config;

# Load default files, read them into lines,
# Add lines based on options provided 
# Write to new copies in the mounted filesystem

sub configure_boot {
  my ($boot) = @_."/boot";
  # Install the UEFI firmware image
  &install_uefi;
  # Change /boot/config.txt to support Raspberry Pi 
  &modify_config;
}

sub install_uefi {
  # EDK2
  # Install UEFI for ARM 
}

sub modify_config {
  # copy default config.
  # Enable GPU drivers for Wayland
  # (add dtoverlay=vc4-kms-v3d-pi5 to boot/config.txt)
  # Give power management control to the Pi
  # (remove force_turbo=1 from /boot/config.txt)
  # Switch from ACPI to Device Tree in UEFI settings
  # (arm_64bit=1
    #enable_uart=1
    #device_tree_address=0x03000000
    #)
}

sub configure_root {
  my ($root) = @_;
  my $config = $root."/etc/nixos/";
  make_path($config);

  open my $nix, '>>', $config.'configuration.nix' or die "$!"; 
  open my $hw, '>>', $config.'hardware-configuration.nix' or die "$!"; 
  # modify based on options: flakes & home manager 

  # TODO: 
  # 2. Option to enable flakes using a config file & `include`.
  # 3. Also check if flakes are already enabled by files in the config-dir
  if ($FLAKES) {

    # Configure nix to use flakes, if it is not already doing so.
    # Add the Pi kernel as a flake. 
  
  }

  # If not using flakes, add kernel package to the configuration directly.
  # Take care that does not get removed!
  else {
    # TODO: Fork this, it shouldn't be that hard to maintain.
     my $kernel = <<'CONFIG';
{
  boot.kernelPackages = (import (builtins.fetchTarball https://gitlab.com/vriska/nix-rpi5/-/archive/main.tar.gz)).legacyPackages.aarch64-linux.linuxPackages_rpi5;
}
CONFIG
    # TODO: Allow user to supply their own configuration.nix file,
    # check for conflicting kernels in the configs.
    print $nix $kernel;
  } 

  close $nix or die "$!";
  close $hw or die "$!";

}


1;

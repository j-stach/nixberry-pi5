
package Config;

# NOTE: These subs all expect the disk root and boot partitions have been mounted
# Use `Device::mount_partitions` for that

use strict; use warnings;


# Configure boot partition to support kernel
sub configure_boot {
  my ($mp, $opts) = @_;
  my $boot = $mp."/boot";
  # Install the Pi5 UEFI firmware image
  &install_uefi;
  # Change /boot/config.txt to support Raspberry Pi 
  &modify_boot_config;
}

# Install EDK2 (UEFI for Pi/ARM)
sub install_uefi {
  my $url = "https://github.com/worproject/rpi5-uefi/releases/download/v0.3/RPi5_UEFI_Release_v0.3.zip";
  # Extract directly into the boot partition
  system("curl -sL $url | unzip -d $boot -") or die "$!";
}

# Modify /boot/config.txt options to enable RPi kernel support
sub modify_boot_config {
  open my $fh, '<', $boot."/config.txt" or die "$!";
  my @lines = <$fh>;
  close $fh;

  # TODO: s0m3_Th!ng=s0m3_Th!ng <- This pattern needs work
  my $pattern = /([.^=]+)=(.*)/;
  my %configs = (
    # GPU for Wayland
    dtoverlay           => "vc4-kms-v3d-pi5",
    # Give power event handling to Pi
    arm_64bit           => 1,
    enable_uart         => 1,
    device_tree_address => "0x03000000",
    force_turbo         => 0,
  );

  # If the line is present but incorrect, replace it
  foreach my $line (@lines) {
    if ($line =~ $pattern) {
      if (exists $configs{$1}) {
        if ($2 ne $configs{$1}) {
          # Warn replacement & modify line
          print "WARNING: Changing the /boot/config.txt option '$1' from '$2' to '$configs{$1}'.\n";
          $line = "$1=%configs{$1}\n";
        }
        delete $configs{$1};
      }
    }
  }

  # Add the remaining necessary options
  foreach my $key (keys %configs) {
    push @lines, "$key=%configs{$key}\n";
  }

  open my $fh, '>', $boot."/config.txt" or die "$!";
  print $fh @lines;
  close $fh;
}


# TODO Configure NixOS according to `configuration.nix` file provided by the user
sub configure_root {
  my ($root, $opts) = @_;
  my $config = $root."/etc/nixos/";
  make_path($config);

  # TODO: if config path is found in options, install it without checking validity
  # Otherwise, get the default config from the repo
  get_config_file($config);
  # Configure NixOS to run on the filesystem
  nixos_install($root, $opts);
}

# Fetch a default config from the repo, based on options provided
sub get_config_file {
  my ($config) = @_;
  my $files = "https://github.com/j-stach/nixberry-pi5/blob/main/files";

  # Copy hardware config from this repo into /etc/nixos/
  system("curl -sL $files/hardware-configuration.nix -O $config");

  # Build filename by matching options
  my $file = "pi5-config-";
  if ($opts->{flakes} == 1)       { $file = $file."f"; }
  if ($opts->{home_manager} == 1) { $file = $file."m"; }
  if ($opts->{hyprland} == 1)     { $file = $file."h"; }

  # Remove trailing hyphen
  if (substr($file, -1) eq '-') { chomp $file }

  # Copy nix config from this repo into /etc/nixos/
  if ($opts->{flakes} == 1)       {
    system("curl -sL $files/$file.nix -o $config/flake.nix");
  } else {
    system("curl -sL $files/$file.nix -o $config/configuration.nix");
  } 

}

# Install NixOS using the configuration provided
sub nixos_install {
  my ($root, $opts) = @_;
  my $config = $root."/etc/nixos/";

  # Use the flake in /etc/nixos that has the system name `rpi5`
  if ($opts->{flakes} == 1)       {
    system("sudo nixos-install --flake $config#pi5Core --root $root --no-bootloader") or die "$!";
  }
  # Or use the file saved at /etc/nixos/configuration.nix
  else {
    system("sudo nixos-install --root $root -I nixos-config=$config/configuration.nix --no-bootloader") or die "$!";
  }

  # Chroot & set root password
  system("echo 'root:root' | sudo chroot $root chpasswd");
}


1;

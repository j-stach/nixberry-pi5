
package Configure;

# NOTE: These subs all expect the disk root and boot partitions have been mounted
# and filesystems set up.
# Use `Device::mount_partitions` and `Device::make_fs`

use strict; use warnings;
use File::Path qw{make_path};


# Configure boot partition to support kernel
sub boot {
  my ($mp, $opts) = @_;
  my $boot = $mp."/boot";
  make_path($boot);

  # Install the Pi5 UEFI firmware image
  install_uefi($boot);
  # Change /boot/config.txt to support Raspberry Pi 
  modify_boot_config($boot);
}

# Install EDK2 (UEFI for Pi/ARM)
sub install_uefi {
  print "Downloading UEFI package...\n";
  my ($boot) = @_;
  my $url = "https://github.com/worproject/rpi5-uefi/releases/download/v0.3/RPi5_UEFI_Release_v0.3.zip";
  # Extract directly into the boot partition
  system("curl -sL $url -o /tmp/nixberry/boot.zip") == 0 or die "$!";
  system("unzip /tmp/nixberry/boot.zip -d $boot") == 0 or die "$!";
}

# Modify /boot/config.txt options to enable RPi kernel support
sub modify_boot_config {
  my ($boot) = @_;

  my @lines;
  if (open my $input, '<', $boot."/config.txt") {
    @lines = <$input>;
    close $input;
  }

  # TODO: s0m3_Th!ng=s0m3_Th!ng <- This pattern needs work
  my $pattern = qr/([.^=]+)=(.*)/;
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
  if (scalar @lines > 0) {
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
  } } }

  # Add the remaining necessary options
  foreach my $key (keys %configs) {
    push @lines, "$key=%configs{$key}\n";
  }

  open my $output, '>', $boot."/config.txt" or die "$!";
  print $output @lines;
  close $output;
}


# TODO Configure NixOS according to `configuration.nix` file provided by the user
sub nixos {
  my ($root, $opts) = @_;
  my $config = $root."/etc/nixos/";
  make_path($config);

  # TODO: if config path is found in options, install it without checking validity
  # Otherwise, get the default config from the repo
  get_config_file($config, $opts);
  # Configure NixOS to run on the filesystem
  nixos_install($root, $opts);
}

# Fetch a default config from the repo, based on options provided
sub get_config_file {
  my ($config, $opts) = @_;
  my $files = "https://raw.githubusercontent.com/j-stach/nixberry-pi5/main/files";

  # Copy hardware config from this repo into /etc/nixos/
  #my $hw_config = "hardware-configuration.nix";
  #system("curl -sL $files/$hw_config -o $config/$hw_config") == 0 or die "$!";

  # Build filename by matching options
  my $file = "pi5-config-";
  if ($opts->{flakes} == 1)       { $file .= "f"; }
  if ($opts->{home_manager} == 1) { $file .= "m"; }
  if ($opts->{hyprland} == 1)     { $file .= "h"; }

  # Remove trailing hyphen
  $file =~ s/-$//;

  # Copy nix config from this repo into /etc/nixos/
  my $nix_config = ($opts->{flakes} == 1) ? "flake.nix" : "configuration.nix";
  system("curl -sL $files/$file.nix -o $config/$nix_config") == 0 or die "$!";

}

# Install NixOS using the configuration provided
sub nixos_install {
  my ($root, $opts) = @_;
  my $config = $root."/etc/nixos/";

  my $command = ($opts->{flakes} == 1) ?
    # Use the flake in /etc/nixos that has the system name `rpi5`
    "nixos-install --flake $config#rpi5 --root $root --no-bootloader" :
    # Or use the file saved at /etc/nixos/configuration.nix
    "nixos-install --root $root -I nixos-config=$config/configuration.nix --no-bootloader";

  # Run the installation command in a temporary nix environment
  system("sudo nix-shell -p nixos-install --run '$command --show-trace'") == 0 or die "$!";

  # Chroot & set root password
  system("echo 'root:root' | sudo chroot $root chpasswd") == 0 or die "$!";
}


1;

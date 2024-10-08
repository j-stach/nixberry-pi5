
#!/usr/bin/perl
use strict; use warnings;
use File::Path qw{make_path};

# Installs NixOS ARM to an SD memory card--
# For use with Raspberry Pi 5 only!

# Vars for the user to set via options.
my $DEVICE = "mmcblk0"; # SD device to overwrite

sub main {

  &parse_options;

  if (&device_ok) { 
    &partition_device;
    &install_nixos;
  }

}

# Parse options: perl install.pl [device] --options
sub parse_options {
  # If options are present, set them as globals.
  # --swap 
  # --config
  # --config-dir
  # --default
}

# Find unmounted devices that could be repartitioned
sub available_devices {
  my @devices = `lsblk -rno NAME,MOUNTPOINT | awk '\$2 == "" && \$1 !~ /p[0-9]+/ { print \$1 }`;
  chomp @devices; 
  return @devices;
}

# Ensures the user-supplied device name is available for partitioning.
sub device_ok {
  my @available = &available_devices;
  foreach my $device (@available) {
    if ($device eq $DEVICE) { return 1 }
  }
  die "ERROR: Device '$DEVICE' is either mounted or nonexistant."
}

# Partition and format the device.
sub partition_device {
  # p1: Boot partition (FAT32)
  # p2: Root partition (rest available)
  # p3: Swap partition (2GB Linux swap, type 82)
  my $commands = <<'COMMANDS';
,256M,0c,
,,,-
,+2G,82
COMMANDS

  open(my $util, '|-', "sfdisk --wipe always $DEVICE") or die "$!";
  print $util $commands;
  close $util or die "ERROR: Partitioning failed: $!";

  # Format BOOT
  system("mkfs.vfat -F 32 $DEVICE.p1") == 0 or die "$!";
  # Format ROOT
  my $ext4_options = "-E lazy_itable_init=0,lazy_journal_init=0";
  system("mkfs.ext4 $ext4_options -F $DEVICE.p2") == 0 or die "$!";
  # Format SWAP
  system("mkswap $DEVICE.p3 && swapon $DEVICE.p3") == 0 or die "$!";
}


sub install_nixos {
  my $mp = "/mnt/sd";
  # Mount ROOT
  make_path($mp);
  system("mount $DEVICE.p2 $mp") == 0 or die "$!";
  # Mount BOOT
  make_path("$mp/boot");
  system("mount $DEVICE.p1 $mp/boot") == 0 or die "$!";
  system("sync") == 0 or die "$!";

  # TODO Set up ROOT and BOOT
  #

  # Clean up 
  system("sync && umount -R $mp") == 0 or die "$!";
}

# Execute the script.
main();


#/usr/bin/perl
package Device;


# Ensures the user-supplied device name is available for partitioning.
sub ok {
  my ($device) = @_;
  my @available = &available_devices;
  foreach my $dev (@available) {
    if ($dev eq $device) { return 1 }
  }
  die "ERROR: Device '$device' is either mounted or nonexistant.";
}

# Find unmounted devices that could be repartitioned
sub available_devices {
  my @devices = `lsblk -rno NAME,MOUNTPOINT | awk '\$2 == "" && \$1 !~ /p[0-9]+/ { print \$1 }`;
  chomp @devices; 
  return @devices;
}


# Partition the device. 
# The options for swap are 2, 1, and 0 GB.
# If 0, no swap partition will be created.
sub partition {
  my ($device, $swap) = @_;

  # p1: Boot partition (FAT32)
    # Boot size does not change, and so is placed first,
    # to preserve the start sectors for both boot and root.
  # p2: Root partition (use all available space)
  my $commands = <<'COMMANDS';
,256M,0c,
,,,-
COMMANDS

  # p3: Swap partition (Linux swap, type 82)
    # Swap is placed last because it can be moved 
    # without disturbing the filesystem.
  unless ($swap == 0) {
    $commands = $commands."\n,+${swap}G,82\n";
  }

  # Wipe never lets us resize the image partitions in place.
  open(my $tool, '|-', "sfdisk --wipe never $device") or die "$!";
  print $tool $commands;
  close $tool or die "$!";
}


1;


## Make file system for newly-partitioned disk.
#sub make_fs {
#  my ($device) = @_;
#  # Format BOOT
#  system("mkfs.vfat -F 32 -n boot $device.p1") == 0 or die "$!";
#  # Format ROOT
#  my $ext4_options = "-L nixos -E lazy_itable_init=0,lazy_journal_init=0";
#  system("mkfs.ext4 $ext4_options -F $device.p2") == 0 or die "$!";
#  # Format SWAP
#  system("mkswap -L swap $device.p3 && swapon $device.p3") == 0 or die "$!";
#}


sub mount_partitions {
  # TODO Check path to make sure no other SDs are mounted.
  my $mp = "/mnt/sd";
  # Mount ROOT
  make_path($mp);
  system("mount $device.p2 $mp") == 0 or die "$!";
  # Mount BOOT
  make_path("$mp/boot");
  system("mount $device.p1 $mp/boot") == 0 or die "$!";
  system("sync") == 0 or die "$!";
  return $mp;
}




#/usr/bin/perl
package Device;

use strict; use warnings;
use File::Path qw{make_path};

# Ensures the user-supplied device name is available for partitioning.
# BUG This is not actually safe at all due to bad regex pattern
sub ok {
  my ($device) = @_;
  my @available = available_devices();
  foreach my $dev (@available) {
    if ($device eq "/dev/".$dev) { return 1 }
  }
  die "ERROR: Device '$device' is either mounted or nonexistant.";
}

# Find unmounted devices that could be repartitioned
sub available_devices {
  my @devices = `lsblk -rno NAME,MOUNTPOINT`;
  chomp @devices; 

  # BUG This pattern does not work correctly
  my $pattern = qr/([a-oq-z0-9]+)(?: [p]?\d+)?/;

  my %taken = ();
  my @available;

  # Per device, if the device or a subdevice is a mount point, exclude it
  # and if it has a "pN" exclude it as well
  foreach my $device (reverse @devices) {
    my ($name, $mp) = split(/\s+/, $device, 2);
    if ($name =~ $pattern) {
      # Exclude device names that are marked as taken
      if (exists $taken{$1}) { next; }
      # Exclude partitions with mount points
      if (defined $mp && $mp ne "") {
        $taken{$1} = 1;
        next;
      }
      push @available, $1;
      $taken{$1} = 1;
    }
  }

  # TODO: Less-lazy solution? This is obviously a bad hack.
  my @acceptable;
  foreach my $dev (@available) {
    if ($dev ne "sda" && $dev ne "sr0") {
      push @acceptable, $dev
    }
  }

  return @acceptable;
}


# Partition the device. 
# The options for swap are 2, 1, and 0 GB.
# If 0, no swap partition will be created.
sub partition {
  my ($opts) = @_;
  my $device = $opts->{device};
  my $swap = $opts->{swap};

  # Get disk size in KB, convert to sectors
  my $size = `sfdisk -s $device`;
  $size = $size * 2;

  my $boot_size = 256 * 2 * 1024; # 256 MB in sectors
  my $swap_size = $swap * 2 * 1024 * 1024; # Swap GB in sectors

  # Root gets the remaining space
  my $root_size = $size - $boot_size;
  $root_size -= $swap_size if $swap > 0;
  $root_size = $root_size * 512 / (1024 * 1024 * 1024); # Root sectors in GB

  # p1: Boot partition (FAT32)
    # Boot size does not change, and so is placed first,
    # to preserve the start sectors for both boot and root.
  # p2: Root partition (use all available space)
  my $commands = ",256M,0c,\n" . ",+${root_size}G,83,-\n";

  # p3: Swap partition (Linux swap, type 82)
    # Swap is placed last because it can be moved 
    # without disturbing the filesystem.
  $commands .= ",-,82\n" unless $swap == 0;

  # Wipe never lets us resize the image partitions in place.
  open(my $tool, '|-', "sfdisk --wipe always $device") or die "$!";
  print $tool $commands;
  close $tool or die "$!";
}


# Make file system for newly-partitioned disk.
sub make_fs {
  my ($device) = @_;
  # Format BOOT at p1
  system("mkfs.vfat -F 32 -n boot ${device}p1") == 0 or die "$!";
  # Format ROOT at p2
  my $ext4_options = "-L nixos -E lazy_itable_init=0,lazy_journal_init=0";
  system("mkfs.ext4 $ext4_options -F ${device}p2") == 0 or die "$!";
  # Format SWAP at p3
  system("mkswap -L swap ${device}p3 && swapon ${device}p3") == 0 or die "$!";
}


# Helper to mount filesystem partitions.
# Returns the mount point as a string.
sub mount_partitions {
  my ($device) = @_;
  # TODO Check path to make sure no other SDs are mounted.
  my $mp = "/mnt/sd";
  # Mount ROOT
  make_path($mp);
  system("mount ${device}p2 $mp") == 0 or die "$!";
  # Mount BOOT
  make_path("$mp/boot");
  system("mount ${device}p1 $mp/boot") == 0 or die "$!";
  system("sync") == 0 or die "$!";
  return $mp;
}


1;

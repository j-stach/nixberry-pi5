
#!/usr/bin/perl

# Installs NixOS ARM to an SD memory card
# (for use with Raspberry Pi 5)
# Note: Requires Nix package manager to build from file.

use strict; use warnings;
use File::Path qw{make_path};

use lib '.';
use Options;
use Configure;
use Device;
use Image;


sub main {
  make_path("/tmp/nixberry");
  # Parse, sanitize & set installation options
  my %opts = Options::set(@ARGV);

  # Select premade image to install, based on options
  #Image::flash(\%opts) or die "$!";
  build_nixos(\%opts);

  # TODO: Mode for building from config

  # Cleanup any temporary files created
  system("sudo rm -rf /tmp/nixberry");

  # TODO: This should change based on flakes...
  print <<'FINISHED';
Installation successful!
It is now safe to remove your SD card.

You can plug the card into your Raspberry Pi 5 and boot.
It should work right away.

The default root password is "root", remember to change it!
The default user is "user", with the password "nixos".
These can be customized in /etc/nixos/configuration.nix.

Enjoy!
FINISHED
}


# TODO: Build NixOS from config file using nixos-install
sub build_nixos {
  my ($opts) = @_;
  Device::partition($opts);
  Device::make_fs($opts->{device});
  my $mp = Device::mount_partitions($opts->{device});

  Configure::boot($mp, $opts);
  Configure::nixos($mp, $opts);

  system("sync && umount -R $mp") == 0 or die "$!";
}

main();


#!/usr/bin/perl
use strict; use warnings;
use File::Path qw{make_path};

use lib '.';
use Options;
use Config;
use Device;

# Installs NixOS ARM to an SD memory card
# (for use with Raspberry Pi 5)
# Note: Requires Nix package manager to build.

sub main {
  my %opts = Options::set(@ARGV);
  Device::ok(%opts{"DEVICE"}) or die "$!";

  if (%opts{"MODE"} eq "build") {
    Device::partition($opts);
    build_nixos($opts);
  } else {
    install_nixos($opts); 
  }

  # TODO: Interactive CLI for options

}

sub build_nixos {
  my ($opts) = @_;
  my $mp = &Device::mount($opts);

  Config::boot($mp, $opts);
  Config::nixos($mp, $opts);

  # TODO: chroot & run nixos-install

  system("sync && umount -R $mp") == 0 or die "$!";
}

sub install_nixos {

  if (%opts{"MODE"} eq "clone") {
    # TODO Get image to flash
  } else {
    #
    # match options to get corresponding image file  
    # flash 8GB image to disk
    # resize root to fit SD, using sfdisk
    # additional options for config 
  }
}


# Execute the script.
main();

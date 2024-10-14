
#!/usr/bin/perl

# Installs NixOS ARM to an SD memory card
# (for use with Raspberry Pi 5)
# Note: Requires Nix package manager to build from file.

use strict; use warnings;
use File::Path qw{make_path};

use lib '.';
use Options;
use Config;
use Device;

sub main {
  # Parse, sanitize & set installation options
  my %opts = Options::set(@ARGV);

  # Select premade image to install, based on options
  install_nixos(\%opts) or die "$!";

  # TODO: Option for building from config

  # Otherwise, prompt the user to select a device
  # TODO: Double check this after setting up config structure 
  print <<'FINISHED';
Installation successful!
It is now safe to remove your SD card.

You can plug the card into your Raspberry Pi 5 and boot.
The default root password is "root", remember to change it!
The default user is "user", with the password "nixos".
These can be customized in /etc/nixos/configuration.nix.

See the NixOS documentation for further assistance.

Enjoy!
FINISHED

}

## TODO: Build NixOS from config file using nixos-install
#sub build_nixos {
#  my ($opts) = @_;
#  Device::partition($opts);
#  my $mp = &Device::mount(%opts{"DEVICE"});
#
#  Config::boot($mp, $opts);
#  Config::nixos($mp, $opts);
#
#  # TODO: chroot & run nixos-install
#
#  system("sync && umount -R $mp") == 0 or die "$!";
#}

sub install_nixos {
  my ($opts) = @_;

  # Based on flags, get 4GB image file 
  # Flash to SD card 
  # Resize swap based on value provided
  # Resize root to fit the remainder of the card
  # TBD: Is this done in `configuration.nix` or with sfdisk? Or both?
}


main();

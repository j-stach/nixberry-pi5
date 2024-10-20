
#!/usr/bin/perl 
package Options;

  # TODO: Interactive CLI for options
  # TODO: Check dependencies for given options. Put this in Utils.pm

use strict; use warnings;
use lib '.';
use Device;


# Parse options and return settings as a hash
sub set {
  my @args = @_;
  my %opts = (
    # Default opts here
    flakes        => 0,
    home_manager  => 0,
    hyprland      => 0,
    swap          => 2,
  );

  # Deafult swap partition size is 2GB
  $opts{swap} = 2;

  foreach my $arg (@args) {
    parse($arg, \%opts);
  }

  return %opts;
}

# Parse argument into flag, option, or device path
sub parse {
  my ($arg, $opts) = @_;

  # Flag pattern
  if ($arg =~ /^-([a-zA-Z]+)$/) { set_flags($opts, $1) }

  # Option pattern
  elsif ($arg =~ /^--(?<opt>[a-zA-Z]+)(?:=(?<value>.*))?$/) { 
    set_option($opts, $+{opt}, $+{value})
  }

  # Device pattern 
  elsif ($arg =~ /^([0-9a-zA-Z\/\-_]+)$/) {
    $opts->{device} = select_device($1);
  }

  else {
    die 
"Unrecognized argument '$arg'.\n
Refer to the README for instructions.\n";
  }
}


# Match flag pattern and set values
sub set_flags {
  my ($opts, $flags) = @_;
  unless ($flags =~ /^(?!.*(.).*\1)[mfh]{1,3}$/) {
    die 
"Unrecognized or duplicate flag in '-$flags'. Valid flags are -f, -m, and -h.\n
Refer to the README for instructions.\n";
  }
  if ($flags =~ /f/) { $opts->{flakes} = 1; }
  if ($flags =~ /m/) { $opts->{home_manager} = 1; }
  if ($flags =~ /h/) { $opts->{hyprland} = 1; }
}


# Match option pattern and set values
sub set_option {
  my ($opts, $option, $value) = @_;

  # Get help info
  if ($option =~ /help/) { 
    die 
"Usage:\n
sudo perl install.pl -[f, m, and/or h] --swap=[0, 1, or 2] /dev/[device name]\n
Refer to the README for instructions.\n";
  }

  # Set swap partition size
  elsif ($option =~ /swap/) {
    unless (
      $value =~ /^\d+$/ && 
      $value <= 2
    ) {
      die "Invalid value for swap size. Expected 2, 1, or 0.\n";
    }
    
    $opts->{swap} = $value; 
  }

}


# Specify the device to which NixOS shall be flashed
sub select_device {
  my ($dev) = @_; 

  # If the user-provided device is good, use it
  if (-b $dev && Device::ok($dev)) { return $dev }

  # Otherwise, prompt the user to select a device
  print <<'PROMPT';
You did not specify a device or the device specified is not flashable.
Would you like to choose a device now? Enter a number:

0   Abort

Available devices: /dev/...
PROMPT

  # List available devices
  my @available = Device::available_devices();
  my $num_devices = @available;

  if ($num_devices == 0) {
    print "None found. \n"
  } else {
    my $count = 1;
    foreach my $dev (@available) {
      if ($count > 20) { 
        print 
"More devices are available but were omitted...\n
Abort, then use `lsblk` to view them.\n";
        last 
      }
      # TODO Get device hardware name, type? Get size?
      print "$count   $dev\n";
    }
  }

  # Wait for user to select a device
  RESPOND:
  print "Your selection: ";
  my $response = <STDIN>;
  unless (
    $response =~ /^\d+$/ && 
    $response <= $num_devices &&
    $response <= 20
  ) { 
    print 
"Invalid selection: '$response'.\n
Please choose one of the options above. Enter 0 to abort.\n";
    goto RESPOND;
  }

  if ($response == 0) { die "Installation cancelled. Bye!" }

  # Get device name by index and return it
  my $choice = $available[$response - 1];
  return $choice
}


1;

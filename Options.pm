
#!/usr/bin/perl 
package Options;

use strict; use warnings;
use lib '.';
use Device;


# Parse options and return settings as a hash
sub set {
  my @args = @_;

  my %opts = ();

  foreach my $arg (@args) {
    parse($arg, \%opts);
  }

  return %opts;
}

# Parse argument into flag, option, or device path
sub parse {
  my ($arg, $opts) = @_;
  if ($arg =~ /^-([a-Z]+)$/) { flag($opts, $1) }
  elsif ($arg =~ /^--(?<opt>[a-Z]+)(?:=(?<value>[]))?$/) { 
    option($opts, $+{opt}, $+{value})
  }
  elsif ($arg =~ /^([0-9a-Z\/\-_])$/) {
    $opts{device} = device($1);
  }
  else {
    die 
"Unrecognized argument '$arg'.\n
Refer to the README for instructions.\n";
  }
}

# Match flag pattern and set values
sub flag {
  my ($opts, $flags) = @_;
  unless ($flags =~ /^(?!.*(.).*\1)[mfh]{1,3}$/) {
    die 
"Unrecognized or duplicate flag in '-$flags'. Valid flags are -f, -m, and -h.\n
Refer to the README for instructions.\n";
  }
  if ($flags) =~ /f/ { $opts->{flakes} = 1; }
  if ($flags) =~ /m/ { $opts->{home_manager} = 1; }
  if ($flags) =~ /h/ { $opts->{hyprland} = 1; }
}

# Match option pattern and set values
sub option {
  my ($opts, $option, $value) = @_;
  if ($option =~ /help/) { 
    die 
"Usage:
sudo perl install.pl -[f, m, and/or h] --swap=[0, 1, or 2] /dev/[DEVICE]\n
Refer to the README for instructions.\n";
  }
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

# Specify the device to which NixOS will be flashed
sub device {
  my ($dev) = @_; 
  # If device cannot be flashed, select a new one
  unless (-b $dev) { $dev = &select_device }
  return $dev
}

# Choose device from selection if one is not provided explicitly
sub select_device {
  # Prompt the user to select a device
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
        break 
      }
      # TODO Get device hardware name? Get size?
      print "$count   $dev\n";
    }
  }

  # Wait for user to select a device
  RESPOND:
  my $response = <STDIN>;
  unless (
    $response =~ /^\d+$/ && 
    $response <= $num_devices &&
    $response <= 20
  ) { 
    print 
"Invalid selection '$response'.\n
Please choose one of the options above.\n";
    goto RESPOND;
  }

  # Get device name by index and return it
  my $choice = $available[$response - 1];
  return $choice
}


1;

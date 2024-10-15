
#!/usr/bin/perl 
package Images;

use lib '.';
use Device;

# Fetch an image based on options selected
sub get {
  my ($opts) = @_;

  # Default image name
  my $image = "nixberry-pi5";

  # Build image name string if options are present
  if (
    $opts->{flakes} ||
    $opts->{home_manager} ||
    $opts->{hyperland} 
  ) { $image = $image."-"; }

  if ($opts->{flakes}) { $image = $image."f"}
  if ($opts->{home_manager}) { $image = $image."m"}
  if ($opts->{hyprland}) { $image = $image."h"}

  my $image_url = "https://github.com/j-stach/nixberry-pi5/blob/main/images/$image.tar.gz";

  # Gets an image from this repo and extracts it
  # This temporary folder is created and cleaned up as part of main()
  system("curl -L $image_url -o /tmp/nixberry") or die"$!";
  system("tar -xzf /tmp/nixberry/$image.tar.gz -C /tmp/nixberry") or die "$!";

  return "/tmp/nixberry/$image.img"
}

# Flash a NixOS image to the SD card and reformat it to spec
sub flash {
  my ($opts) = @_;
  my $device = $opts->{device};

  # Match the options to the correct image & flash it
  my $image = get($opts);
  system("sudo dd if=$image of=$device bd=4M status=progress");
  system("sync");

  # Resize to set swap and ensure root uses all available space
  Device::partition($device, $opts->{swap});
  system("sudo resize2fs $device") or die "$!";
}

1;

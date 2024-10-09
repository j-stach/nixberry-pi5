
package Options;

# Parse options: perl install.pl [device] --options
sub set {
  my @args = @_;

  my %opts = ();
  # TODO: 
  # Fresh install from default 
  # or modify config & build image using nix
  # Check first command 


  # If options are present, set them as globals.
  # --swap <0-4 OK> <4+ WARN & CONFIRM> <Oversize ERROR>
  # --config <filepath>
  # --config-dir <dirname>
  # --flake
  # --home
  # --hypr
  # --env=true (tries to use locales from host machine)
  # --default
  # Leave this alone for now, but keep it in mind.
  return %opts;
}

sub parse {
  # TODO Parse argument:
  # --option=value
  # -o flags? What is flag vs option?
  # return (option, value) strings to set in hashmap
}



1;

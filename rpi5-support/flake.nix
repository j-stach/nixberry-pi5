{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";

  outputs = { nixpkgs, ... }: {
    legacyPackages.aarch64-linux = with nixpkgs.legacyPackages.aarch64-linux; rec {

      linux_rpi5 = stdenv.mkDerivation (lib.overrideDerivation (buildLinux {
        version = "6.1.63-stable_20231123";
        modDirVersion = "6.1.63";

        src = fetchFromGitHub {
          owner = "raspberrypi";
          repo = "linux";
          rev = "stable_20231123";
          hash = "sha256-4Rc57y70LmRFwDnOD4rHoHGmfxD9zYEAwYm9Wvyb3no=";
        };

        defconfig = "bcm2712_defconfig";  # Raspberry Pi 5 only

        features = {
          efiBootStub = false;
        } // (args.features or {});

        extraMeta = {
          platforms = with lib.platforms; arm ++ aarch64;
          hydraPlatforms = [ "aarch64-linux" ];
        };

      } (oldAttrs: {
        postConfigure = ''
          sed -i $buildRoot/.config -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
          sed -i $buildRoot/include/config/auto.conf -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
        '';

        postFixup = ''
          dtbDir="$out/dtbs/broadcom"
          rm $dtbDir/bcm283*.dtb
          copyDTB() {
            cp -v "$dtbDir/$1" "$dtbDir/$2"
          }
          copyDTB bcm2712-rpi-5-b.dtb bcm2838-rpi-5-b.dtb
        '';
      })));

      linuxPackages_rpi5 = linuxPackagesFor linux_rpi5;
    };
  };
}


# nixberry
Installation script for plug & play NixOS on the Raspberry Pi 5.

# Work in progress! Don't use me yet!
Tests needed:
- [ ] ...

## Materials:
- Raspberry Pi 5 
- Computer with Linux
- Micro-SD card (Minimum 8GB. Recommend at least 16GB for Hyprland desktop.)
- Micro-SD reader/adapter

## Usage:
The script can be used one of two ways: <br>
**A.** Clone a premade image from this repo and flash it <br>
**B.** Build NixOS from configuration files using Nix package manager **(Not yet implemented)** <br>

### A. Flash a premade NixOS image
The images in this repo were created by following the wiki instructions for [NixOS on ARM/Raspberry Pi 5](https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_5).

```
sudo perl install.pl DEVICE
```
The default command will install NixOS with the minimum configuration needed to support the Pi 5. <br>
DEVICE is the name of the SD card to be flashed, which should be something like `/dev/mmcblk0`.
If you don't provide a device name, the script will get a list of devices available for writing and ask you to choose one. <br>
**NOTE:** Make sure the SD card is not mounted before you run this script.

Omitting any of the following options will cause the script to follow its default behavior.

#### Options for installation:
- `-f` Configure NixOS to use a flakes to define the system, and include the Pi-supported kernel as a flake.
- `-m` Confifure NixOS to use Home Manager. If `-f`, it will include Home Manager as its own flake. 
- `-h` Include `hyprland` (with `hyprpaper` and `swaylock`) as the desktop environment, and install `alacritty` as the default terminal emulator. If `-m`, it will configure Hyprland using Home Manager instead of `hyprland.conf`.

#### Additional options:
- `--swap=X` Use *X* to set the size of the swap partition (in GB). 
For simplicity's sake and to preserve the longevity of the SD card, the choices for X are limited to `2` (default), `1`, and `0`. 
However, if you bully me enough, I am willing to change my mind about this.
Setting X to 0 will format the card without a swap partition. 

#### Example:
```
sudo perl install.pl -fmh --swap=1 /dev/mmcblk0
```
This command installs NixOS to `mmcblk0`, sets a reduced (1GB) swap partition, and configures Nix to include flakes, Home Manager, and Hyprland. This would fit comfortably on a 16GB+ memory card.

#### Install now:
```
TODO
```


### B. Build NixOS from configuration file using Nix (WIP)
**Work in-progress**
- Requires Nix package manager. 
- Will build directly on the SD card using `nixos-build` and an existing `configuration.nix` file.

## Dev resources
- https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_5
- https://github.com/worproject/rpi5-uefi#getting-started
- https://nixos.wiki/wiki/NixOS_on_ARM/UEFI
- https://gitlab.com/vriska/nix-rpi5
- https://nixos.wiki/wiki/flakes
- https://github.com/worproject/rpi5-uefi/releases


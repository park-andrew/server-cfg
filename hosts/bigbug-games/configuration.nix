# Host-specific settings for "bigbug-games".
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk.nix
    ./minecraft.nix
  ];

  networking.hostName = "bigbug-games";

  # Pick ONE bootloader to match the machine.
  # UEFI:
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Legacy BIOS (comment out the two lines above and use this instead):
  # boot.loader.grub.enable = true;
  # boot.loader.grub.device = "/dev/sda";

  # Static IP. Matches any wired interface (Proxmox VirtIO is usually ens18).
  # CHECK the /24 subnet, gateway and DNS against your network before deploying.
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.networks."10-lan" = {
    matchConfig.Name = "en*";
    address = [ "10.27.5.67/24" ];
    gateway = [ "10.27.5.1" ];
    dns = [ "10.27.5.1" "1.1.1.1" ];
    linkConfig.RequiredForOnline = "routable";
  };

  # Proxmox VM: lets Proxmox see the IP and shut the VM down cleanly.
  # Also tick "QEMU Guest Agent" in the VM's Options tab in Proxmox.
  services.qemuGuest.enable = true;

  # Set to the NixOS release this machine was first installed with. Don't change it later.
  system.stateVersion = "26.05";
}

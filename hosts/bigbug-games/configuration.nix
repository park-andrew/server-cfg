# Host-specific settings for "bigbug-games".
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk.nix
    ./minecraft.nix
  ];

  networking.hostName = "bigbug-games";

  # GRUB boots on both Proxmox BIOS types: SeaBIOS (legacy) and OVMF (UEFI).
  # The install disk is picked up from disk.nix (disko sets boot.loader.grub.devices).
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true; # no NVRAM entries needed, so the BIOS type can change later
  };

  # Static IP 10.27.5.67, plus a DHCP address as a fallback: if the static settings are ever
  # wrong, the VM is still reachable at its DHCP address (shown on the Proxmox Summary page).
  # Matches any wired interface (Proxmox VirtIO is usually ens18).
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.networks."10-lan" = {
    matchConfig.Name = "en*";
    address = [ "10.27.5.67/16" ]; # /16 so the 10.27.1.1 gateway is on the same network
    gateway = [ "10.27.1.1" ];
    dns = [ "10.27.1.1" "1.1.1.1" ];
    networkConfig.DHCP = "ipv4";
    linkConfig.RequiredForOnline = "routable";
  };

  # Serial console, so Proxmox's xterm.js console works (it supports copy and paste).
  # In Proxmox: VM -> Hardware -> Add -> Serial Port (0), then Console -> xterm.js.
  boot.kernelParams = [ "console=tty1" "console=ttyS0,115200" ];
  boot.loader.grub.extraConfig = ''
    serial --unit=0 --speed=115200
    terminal_input serial console
    terminal_output serial console
  '';

  # Compressed swap in RAM: a safety net so a memory spike slows things down instead of
  # killing a Minecraft server.
  zramSwap.enable = true;

  # Proxmox VM: lets Proxmox see the IP and shut the VM down cleanly.
  # Also tick "QEMU Guest Agent" in the VM's Options tab in Proxmox.
  services.qemuGuest.enable = true;

  # Set to the NixOS release this machine was first installed with. Don't change it later.
  system.stateVersion = "26.05";
}

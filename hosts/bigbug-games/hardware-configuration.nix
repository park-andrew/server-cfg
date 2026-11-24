# Hardware for the Proxmox VM. Filesystems come from disk.nix (disko), not from here.
{ lib, modulesPath, ... }:
{
  # VirtIO drivers for disk, network and balloon.
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

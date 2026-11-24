# Disk layout for the Proxmox VM, managed by disko.
# disko formats the disk at install time and generates the fileSystems entries.
# Partitions are mounted by label, so `device` only matters when formatting.
{
  disko.devices.disk.main = {
    type = "disk";
    # VirtIO SCSI (Proxmox default) = /dev/sda. VirtIO Block = /dev/vda.
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}

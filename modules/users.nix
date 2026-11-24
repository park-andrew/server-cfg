# Human login accounts. To add someone: copy a block, change the name and key, redeploy.
#   extraGroups:
#     "wheel" = can use sudo (admins only)
#     "mc"    = can edit files in /srv/minecraft (only exists on hosts that import minecraft.nix)
{ pkgs, ... }:
{
  # Immutable users: accounts and groups come only from this config. useradd/passwd changes
  # are reverted on every rebuild, and accounts removed from here are deleted.
  users.mutableUsers = false;

  # Root password for the Proxmox console, in case SSH breaks. The hash lives on the server,
  # not in this public repo. Create it once (as root):
  #   nix run nixpkgs#mkpasswd -- -m yescrypt > /var/lib/root-password && chmod 600 /var/lib/root-password
  # Until that file exists, root login is locked.
  users.users.root.hashedPasswordFile = "/var/lib/root-password";

  users.users.andrew = {
    isNormalUser = true;
    extraGroups = [ "wheel" "mc" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC+m4orHAiFDRtD3pSKjDG6FK0xvWFT27wf+upDVltJd andew@sus"
    ];
  };

  # Example of a non-admin who can manage Minecraft files:
  # users.users.friend = {
  #   isNormalUser = true;
  #   extraGroups = [ "mc" ];
  #   openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA... friend@pc" ];
  # };
}

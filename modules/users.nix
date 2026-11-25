# Human login accounts. To add someone: copy a block, change the name and key, redeploy.
#   extraGroups:
#     "wheel" = can use sudo (admins only)
#     "mc"    = can edit files in /srv/minecraft (only exists on hosts that import minecraft.nix)
{ pkgs, ... }:
{
  # Immutable users: accounts and groups come only from this config. useradd/passwd changes
  # are reverted on every rebuild, and accounts removed from here are deleted.
  users.mutableUsers = false;

  # Root password for the Proxmox console, in case SSH breaks (SSH itself refuses root).
  # The password is a random 5-word passphrase, kept in 1Password as "bigbug-games root" (Private
  # vault); with yescrypt, publishing the hash is safe. To change it: pick a new random passphrase,
  # then run  mkpasswd -m yescrypt  and paste the result here.
  users.users.root.hashedPassword = "$y$j9T$I6/iKS3LYYrFujlvJenoj.$5Ev9TWTp.kwvgz9J8PX/kBl43qGeMxqfFqAvvsvYA90";

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

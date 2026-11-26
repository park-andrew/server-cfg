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

  programs.fish.enable = true;

  users.users.andrew = {
    isNormalUser = true;
    extraGroups = [ "wheel" "mc" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC+m4orHAiFDRtD3pSKjDG6FK0xvWFT27wf+upDVltJd andew@sus"
    ];
  };

  # Keys copied from github:alx-alexpark/server-cfg (modules/base.nix): hardware security keys.
  users.users.alex = {
    isNormalUser = true;
    extraGroups = [ "wheel" "mc" ];
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIAKWfF9y67GxL3jIFcQfWvTOBOyIPtreimhYpxTHJ3CcAAAABHNzaDo= a@susbook.local"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAINlmapiWuvpREQGuJJBP/Pv2N3Tt9zIhXIkcAlFt0ZsnAAAABHNzaDo= a@susbook.local"
    ];
  };

  users.users.keaton = {
    isNormalUser = true;
    extraGroups = [ "mc" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOjzQuYifybb86HagJxZEHeTTCxnb1pRzTlmxpY/d/ST arch@PiclOS-1000"
    ];
  };

  users.users.adil = {
    isNormalUser = true;
    extraGroups = [ "mc" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA0Qa7CYJgqHd8uzf4wWYMdQrrIE3fbqDFn4GfojeZoS adil raza@Adil"
    ];
  };

  # Example of a non-admin who can manage Minecraft files:
  # users.users.friend = {
  #   isNormalUser = true;
  #   extraGroups = [ "mc" ];
  #   openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA... friend@pc" ];
  # };
}

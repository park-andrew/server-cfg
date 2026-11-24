# Human login accounts. To add someone: copy a block, change the name and key, redeploy.
#   extraGroups:
#     "wheel" = can use sudo (admins only)
#     "mc"    = can edit files in /srv/minecraft (only exists on hosts that import minecraft.nix)
{ pkgs, ... }:
{
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

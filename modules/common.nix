# Settings shared by every host.
{ config, pkgs, inputs, ... }:
let
  # `rebuild` pulls the latest config from GitHub and applies it to this machine.
  #   rebuild           apply now (switch)
  #   rebuild boot      apply on next reboot
  #   rebuild test      apply now, but revert on reboot
  rebuild = pkgs.writeShellApplication {
    name = "rebuild";
    text = ''
      action="''${1:-switch}"
      shift || true
      echo "Rebuilding ${config.networking.hostName} from github:park-andrew/server-cfg ($action)"
      exec /run/wrappers/bin/sudo /run/current-system/sw/bin/nixos-rebuild "$action" \
        --flake "github:park-andrew/server-cfg#${config.networking.hostName}" \
        --refresh "$@"
    '';
  };
in
{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    # Make `nix run nixpkgs#foo` use the same nixpkgs as the system.
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    # Tailscale: direct peer-to-peer connections, and trust traffic from the tailnet.
    allowedUDPPorts = [ config.services.tailscale.port ];
    trustedInterfaces = [ "tailscale0" ];
  };

  # Tailscale VPN. One-time login after the first deploy:  sudo tailscale up
  # (The auth key is not stored here: this repo is public.)
  services.tailscale.enable = true;

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    rebuild
    git
    vim
    htop
    curl
    wget
    tmux
  ];
}

# Minecraft servers are managed by hand in /srv/minecraft/<name>/ (modded, so nothing declarative).
# This file provides the mc account, the shared folder, Java, the mcctl tool, and boot autostart.
{ pkgs, ... }:
let
  mcctl = pkgs.writeShellApplication {
    name = "mcctl";
    runtimeInputs = with pkgs; [ tmux coreutils gnutar gzip gnugrep jdk21_headless ];
    text = builtins.readFile ./mcctl.sh;
  };
in
{
  # Service account: no password and no SSH key, so nobody logs in as it directly.
  # People in the mc group act as it through `mcctl`; admins can also `sudo -iu mc`.
  users.groups.mc = { };
  users.users.mc = {
    isSystemUser = true;
    group = "mc";
    home = "/srv/minecraft";
    createHome = false; # created by tmpfiles below with the right permissions
    shell = pkgs.bash;
  };

  systemd.tmpfiles.rules = [
    # 2770: owner and group read/write, nobody else; setgid keeps new files in group mc.
    "d /srv/minecraft 2770 mc mc -"
    # Default ACL: new files are group-writable whether mc or a person created them.
    "A+ /srv/minecraft - - - - default:user::rwx,default:group::rwx,default:other::---"
  ];

  # Members of mc may run mcctl as mc without a password, and nothing else.
  security.sudo.extraRules = [
    {
      groups = [ "mc" ];
      runAs = "mc";
      commands = [
        {
          command = "/run/current-system/sw/bin/mcctl";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  environment.systemPackages = [
    mcctl
    pkgs.jdk21_headless
    pkgs.unzip
  ];

  # Fixed paths for older Java, for start.sh files that need it.
  environment.etc."minecraft/java17".source = pkgs.jdk17_headless;
  environment.etc."minecraft/java8".source = pkgs.jdk8_headless;

  programs.bash.interactiveShellInit = builtins.readFile ./mcctl-completion.bash;

  # Starts servers marked with `mcctl autostart <name> on` at boot; stops all servers cleanly at shutdown.
  systemd.services.minecraft = {
    description = "Minecraft servers (autostart)";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    # Don't stop every server just because a deploy changed this unit or mcctl.
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "mc";
      Group = "mc";
      UMask = "0002";
      ExecStart = "${mcctl}/bin/mcctl boot";
      ExecStop = "${mcctl}/bin/mcctl stop-all";
      TimeoutStopSec = "10min";
    };
  };

  networking.firewall.allowedTCPPorts = [ 25565 ];
}

# mcctl: manage the Minecraft servers in /srv/minecraft/<name>/
# Each server runs inside a tmux session (owned by the mc account) named after its folder.

ROOT=/srv/minecraft
SOCK="$ROOT/.tmux.sock"
BACKUPS="$ROOT/.backups"
SELF=/run/current-system/sw/bin/mcctl
STOP_TIMEOUT=90

# Always act as the mc account. Members of the mc group may do this without a password.
if [ "$(id -un)" != mc ]; then
  exec /run/wrappers/bin/sudo -u mc "$SELF" "$@"
fi
umask 002

usage() {
  cat <<'EOF'
mcctl: manage Minecraft servers in /srv/minecraft/<name>/

  mcctl list                     all servers, running or not
  mcctl status   <name>
  mcctl start    <name>
  mcctl stop     <name>          sends "stop", waits for a clean shutdown
  mcctl restart  <name>
  mcctl console  <name>          attach to the console (detach: Ctrl-b then d)
  mcctl cmd      <name> <text>   run one console command, e.g. mcctl cmd smp say hi
  mcctl logs     <name>          follow logs/latest.log (Ctrl-c to quit)
  mcctl new      <name>          create a server folder with a start.sh template
  mcctl autostart <name> on|off  start this server at boot
  mcctl backup   <name>          tar.gz the server folder into /srv/minecraft/.backups
  mcctl fix-perms <name>         make every file owned by mc and group-writable
                                 (also done automatically by start)
  mcctl stop-all

A server is started with start.sh in its folder, or run.sh if there is no start.sh
(Forge/NeoForge modpacks ship run.sh).
EOF
}

die() {
  echo "mcctl: $*" >&2
  exit 1
}

t() { tmux -S "$SOCK" "$@"; }

servers() {
  local d
  for d in "$ROOT"/*/; do
    [ -d "$d" ] && basename "$d"
  done
  return 0
}

valid_name() {
  [[ "$1" =~ ^[A-Za-z0-9_-]+$ ]] || die "server names may only use letters, digits, - and _"
}

need_server() {
  [ -n "${1:-}" ] || die "which server? (see: mcctl list)"
  valid_name "$1"
  [ -d "$ROOT/$1" ] || die "no server '$1' (see: mcctl list)"
}

running() { t has-session -t "=$1" 2>/dev/null; }

need_running() { running "$1" || die "'$1' is not running (start it: mcctl start $1)"; }

launcher() {
  local f
  for f in start.sh run.sh; do
    if [ -f "$ROOT/$1/$f" ]; then
      echo "$f"
      return 0
    fi
  done
  return 1
}

send() { # send <name> <console text>
  t send-keys -t "=$1:" -l -- "$2"
  t send-keys -t "=$1:" Enter
}

cmd_list() {
  local s state auto any=0
  printf '%-24s %-9s %s\n' NAME STATE AUTOSTART
  while read -r s; do
    [ -n "$s" ] || continue
    any=1
    if running "$s"; then state=running; else state=stopped; fi
    if [ -f "$ROOT/$s/.autostart" ]; then auto=on; else auto=off; fi
    printf '%-24s %-9s %s\n' "$s" "$state" "$auto"
  done < <(servers)
  [ "$any" = 1 ] || echo "(no servers yet; create one with: mcctl new <name>)"
}

cmd_status() {
  need_server "$1"
  if running "$1"; then echo "$1: running"; else echo "$1: stopped"; fi
  if [ -f "$ROOT/$1/.autostart" ]; then echo "autostart: on"; else echo "autostart: off"; fi
}

tmux_up() { t list-sessions >/dev/null 2>&1; }

# Files unzipped or copied in by a person keep their owner/modes; hand them back to mc.
fix_perms() { /run/wrappers/bin/sudo -n /run/current-system/sw/bin/mcctl-fixperms "$1"; }

cmd_fix_perms() {
  need_server "$1"
  fix_perms "$1"
}

cmd_start() {
  need_server "$1"
  running "$1" && die "'$1' is already running (attach: mcctl console $1)"
  # Servers must run inside the tmux server owned by minecraft.service, so shutdown stops them cleanly.
  tmux_up || die "the minecraft service is not running; start it with: sudo systemctl start minecraft"
  local f
  f=$(launcher "$1") || die "no start.sh or run.sh in $ROOT/$1"
  fix_perms "$1" >/dev/null || echo "warning: could not fix permissions in $ROOT/$1" >&2
  t new-session -d -s "$1" -c "$ROOT/$1" "bash ./$f"
  sleep 3
  if running "$1"; then
    echo "started $1 (console: mcctl console $1)"
  else
    die "'$1' exited right away. Run it by hand to see why: sudo -iu mc, then cd $ROOT/$1 && bash ./$f"
  fi
}

cmd_stop() {
  need_server "$1"
  need_running "$1"
  echo "stopping $1..."
  send "$1" stop
  local i
  for ((i = 0; i < STOP_TIMEOUT; i++)); do
    running "$1" || {
      echo "stopped $1"
      return 0
    }
    sleep 1
  done
  echo "$1 did not stop within ${STOP_TIMEOUT}s; killing it" >&2
  t kill-session -t "=$1"
}

cmd_console() {
  need_server "$1"
  need_running "$1"
  echo "Attaching to $1. Detach with Ctrl-b then d (typing 'stop' shuts the server down)."
  sleep 1
  t attach-session -t "=$1"
}

cmd_cmd() {
  local name="${1:-}"
  shift || true
  need_server "$name"
  need_running "$name"
  [ $# -gt 0 ] || die "usage: mcctl cmd <name> <command>"
  send "$name" "$*"
  sleep 1
  t capture-pane -p -t "=$name:" | grep -v '^[[:space:]]*$' | tail -n 10 || true
}

cmd_logs() {
  need_server "$1"
  local log="$ROOT/$1/logs/latest.log"
  [ -f "$log" ] || die "no log yet at $log"
  tail -n 50 -F "$log"
}

cmd_new() {
  [ -n "${1:-}" ] || die "usage: mcctl new <name>"
  valid_name "$1"
  [ -e "$ROOT/$1" ] && die "'$1' already exists"
  mkdir -p "$ROOT/$1"
  cat >"$ROOT/$1/start.sh" <<'EOF'
#!/usr/bin/env bash
# Run by `mcctl start`. Edit the jar name and memory for this server.
# Modpack ships its own run.sh (Forge/NeoForge)? Delete this file and mcctl will use run.sh.
#
# Java: `java` is 21 (Minecraft 1.20.5+). For older versions use
#   /etc/minecraft/java17/bin/java   (1.18 - 1.20.4)
#   /etc/minecraft/java8/bin/java    (1.16 and older)
exec java -Xms2G -Xmx6G -jar server.jar nogui
EOF
  chmod 775 "$ROOT/$1/start.sh"
  echo "created $ROOT/$1"
  echo "next: put the server files there, edit start.sh, accept the EULA (eula.txt), then: mcctl start $1"
}

cmd_autostart() {
  need_server "$1"
  case "${2:-}" in
    on) touch "$ROOT/$1/.autostart" && echo "$1 will start at boot" ;;
    off) rm -f "$ROOT/$1/.autostart" && echo "$1 will not start at boot" ;;
    *) die "usage: mcctl autostart <name> on|off" ;;
  esac
}

cmd_backup() {
  need_server "$1"
  mkdir -p "$BACKUPS"
  local file
  file="$BACKUPS/$1-$(date +%Y-%m-%d_%H%M%S).tar.gz"
  if running "$1"; then
    echo "pausing world saves on $1..."
    send "$1" "save-off"
    send "$1" "save-all flush"
    sleep 10
    # shellcheck disable=SC2064
    trap "send '$1' save-on" EXIT
  fi
  echo "writing $file"
  tar -czf "$file" -C "$ROOT" --exclude="$1/logs" --exclude="$1/crash-reports" "$1"
  echo "done ($(du -h "$file" | cut -f1))"
}

cmd_stop_all() {
  local s
  while read -r s; do
    [ -n "$s" ] || continue
    if ! (cmd_stop "$s"); then echo "failed to stop $s" >&2; fi
  done < <(t list-sessions -F '#{session_name}' 2>/dev/null)
}

cmd_boot() {
  local s
  # Start the shared tmux server and keep it alive even with no servers running.
  t start-server \; set-option -g exit-empty off
  while read -r s; do
    [ -f "$ROOT/$s/.autostart" ] || continue
    (cmd_start "$s") || echo "failed to start $s" >&2
  done < <(servers)
}

sub="${1:-help}"
shift || true
case "$sub" in
  list | ls) cmd_list ;;
  status) cmd_status "${1:-}" ;;
  start) cmd_start "${1:-}" ;;
  stop) cmd_stop "${1:-}" ;;
  restart)
    need_server "${1:-}"
    if running "$1"; then cmd_stop "$1"; fi
    cmd_start "$1"
    ;;
  console | attach | c) cmd_console "${1:-}" ;;
  cmd | run) cmd_cmd "$@" ;;
  logs | log) cmd_logs "${1:-}" ;;
  new) cmd_new "${1:-}" ;;
  autostart) cmd_autostart "${1:-}" "${2:-}" ;;
  backup) cmd_backup "${1:-}" ;;
  fix-perms | fixperms) cmd_fix_perms "${1:-}" ;;
  stop-all) cmd_stop_all ;;
  boot) cmd_boot ;;
  help | -h | --help) usage ;;
  *)
    usage >&2
    exit 1
    ;;
esac

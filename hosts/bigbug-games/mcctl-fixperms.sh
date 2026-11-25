# mcctl-fixperms <name>: give /srv/minecraft/<name> back to mc and make it group-writable.
# Runs as root (members of the mc group may run it via sudo), so it is deliberately strict:
# one server folder at a time, never a symlink, and symlinks inside are never followed.

ROOT=/srv/minecraft
name="${1:-}"

if ! [[ "$name" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "usage: mcctl fix-perms <name>" >&2
  exit 1
fi

dir="$ROOT/$name"
if [ -L "$dir" ] || [ ! -d "$dir" ]; then
  echo "mcctl: no server '$name'" >&2
  exit 1
fi

chown -R -P mc:mc -- "$dir"
chmod -R u+rwX,g+rwX -- "$dir"
find "$dir" -type d -exec chmod g+s -- {} +
echo "fixed permissions in $dir"

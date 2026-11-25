#!/usr/bin/env bash
# Run inside the NixOS installer so nixos-anywhere can log in with the admin SSH key (no password).
# Typeable in consoles that mangle shifted characters:
#   curl --location raw.githubusercontent.com/park-andrew/server-cfg/main/bootstrap.sh -o b; bash b
set -eu
mkdir -p ~/.ssh
curl -fsSL https://raw.githubusercontent.com/park-andrew/server-cfg/main/modules/users.nix \
  | grep -o 'ssh-ed25519 [^"]*' >~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
echo "authorized keys:"
cat ~/.ssh/authorized_keys
echo
ip -br -4 a

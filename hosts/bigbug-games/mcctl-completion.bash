# Tab completion for mcctl: subcommands, then server names.
_mcctl() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  if [ "$COMP_CWORD" -eq 1 ]; then
    mapfile -t COMPREPLY < <(compgen -W "list status start stop restart console cmd logs new autostart backup fix-perms stop-all help" -- "$cur")
  elif [ "$COMP_CWORD" -eq 2 ]; then
    mapfile -t COMPREPLY < <(compgen -W "$(ls /srv/minecraft 2>/dev/null)" -- "$cur")
  elif [ "$COMP_CWORD" -eq 3 ] && [ "${COMP_WORDS[1]}" = autostart ]; then
    mapfile -t COMPREPLY < <(compgen -W "on off" -- "$cur")
  fi
}
complete -F _mcctl mcctl

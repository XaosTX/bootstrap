#!/bin/sh
# lib/log.sh — shared logging + tiny helpers (lifted from init.sh)

log_header()  { printf -- '\n\033[1m%b\033[0m\n' "$@"; }
log_success() { printf -- ' \033[1;32m✔\033[0m  %b\n' "$@"; }
log_error()   { printf -- ' \033[1;31m✖\033[0m  %b\n' "$@" >&2; }
log_arrow()   { printf -- ' \033[1;34m➜\033[0m  %b\n' "$@"; }

# Run a command, or just print it under --dry-run
run() {
  if [ "${DRY_RUN:-0}" = 1 ]; then
    log_arrow "[dry-run] $*"
  else
    "$@"
  fi
}

# Is $1 in the space-separated $ITEMS list this group was dispatched with?
has_item() {
  case " ${ITEMS:-} " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

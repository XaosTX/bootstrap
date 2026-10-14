#!/bin/sh
# lib/menu.sh — checkbox multi-select menu with batch toggle (design §4)
#
# Reads from /dev/tty (not stdin) so it works under `curl … | sh`.
# With no TTY available, the preselection is accepted as-is.

# get_item_at_index <space-list> <1-based-index>
get_item_at_index() {
  i=1
  for item in $1; do
    if [ "$i" -eq "$2" ] 2>/dev/null; then
      echo "$item"
      return
    fi
    i=$((i + 1))
  done
}

# prompt_menu <heading> <all options> <preselected options>
# Result: space-separated selection in $prompt_selections
prompt_menu() {
  pm_heading=$1
  pm_options=$2
  pm_selected=" $3 "

  if [ ! -r /dev/tty ]; then
    log_arrow "No TTY — accepting preselection: ${3:-<none>}"
    prompt_selections=$3
    return
  fi

  while :; do
    log_header "$pm_heading"
    i=1
    for pm_opt in $pm_options; do
      case "$pm_selected" in
        *" $pm_opt "*) printf ' [\033[1;32mx\033[0m] %2d) %s\n' "$i" "$pm_opt" ;;
        *)             printf ' [ ] %2d) %s\n' "$i" "$pm_opt" ;;
      esac
      i=$((i + 1))
    done

    printf 'Toggle (numbers separated by spaces, ENTER to confirm): '
    read -r pm_nums </dev/tty || pm_nums=""
    [ -z "$(echo "$pm_nums" | tr -d ' ')" ] && break

    for pm_num in $pm_nums; do
      pm_opt=$(get_item_at_index "$pm_options" "$pm_num")
      [ -z "$pm_opt" ] && continue
      case "$pm_selected" in
        *" $pm_opt "*) pm_selected=$(printf '%s' "$pm_selected" | sed "s/ $pm_opt / /") ;;
        *)             pm_selected="$pm_selected$pm_opt " ;;
      esac
    done
  done

  # normalize whitespace; read by callers after we return
  # shellcheck disable=SC2086,SC2034,SC2116
  prompt_selections=$(echo $pm_selected)
}

#!/usr/bin/env bash
#
# ssh-split.sh — tmux split that follows the current ssh session.
#
# If the pane you press the key in is connected to a remote host over
# ssh/mosh/autossh, the new pane runs the same ssh command line, so it lands
# on the same machine (reusing ControlMaster connections when configured).
# Otherwise it is a plain split.
#
# Bind it with the split options you want, e.g.:
#   bind % run-shell "~/.config/tmux/ssh-split.sh -h -l 33%"
#
# Testing overrides:
#   SSH_SPLIT_PANE=<target-pane>   inspect that pane instead of the current one
#   SSH_SPLIT_DRY_RUN=1            print the split command instead of running it

set -u

pane_id="${SSH_SPLIT_PANE:-}"
tmux_args=()
if [[ -n "$pane_id" ]]; then
	tmux_args=(-t "$pane_id")
fi

pane_pid="$(tmux display-message "${tmux_args[@]}" -p '#{pane_pid}' 2>/dev/null)" || exit 1
tty_name="$(tmux display-message "${tmux_args[@]}" -p '#{pane_tty}' 2>/dev/null)"
cwd="$(tmux display-message "${tmux_args[@]}" -p '#{pane_current_path}' 2>/dev/null)"

is_ssh_cmd() {
	local first="${1%%[[:space:]]*}"
	first="${first##*/}"
	case "$first" in
	ssh | mosh | autossh) return 0 ;;
	esac
	return 1
}

ssh_cmd=""
if [[ -n "$tty_name" ]]; then
	tty_name="${tty_name#/dev/}"
	# Processes attached to the pane's tty: the pane shell plus whatever it is
	# running in the foreground (e.g. ssh). Background jobs are skipped — their
	# stat has no '+'.
	while IFS= read -r pid; do
		[[ -z "$pid" ]] && continue
		stat="$(ps -o stat= -p "$pid" 2>/dev/null | tr -d ' ')"
		[[ "$stat" != *+* ]] && continue
		cmd="$(ps -ww -o command= -p "$pid" 2>/dev/null)"
		if is_ssh_cmd "$cmd"; then
			ssh_cmd="$cmd"
			break
		fi
	done < <(ps -t "$tty_name" -o pid= 2>/dev/null)
fi

# Belt and braces: `exec ssh` makes the ssh process the pane process itself.
if [[ -z "$ssh_cmd" ]]; then
	stat="$(ps -o stat= -p "$pane_pid" 2>/dev/null | tr -d ' ')"
	cmd="$(ps -ww -o command= -p "$pane_pid" 2>/dev/null)"
	if [[ "$stat" == *+* ]] && is_ssh_cmd "$cmd"; then
		ssh_cmd="$cmd"
	fi
fi

args=("$@")
if [[ -n "$cwd" ]]; then
	args+=(-c "$cwd")
fi
if [[ -n "$ssh_cmd" ]]; then
	args+=("$ssh_cmd")
fi

if [[ "${SSH_SPLIT_DRY_RUN:-0}" == "1" ]]; then
	printf 'tmux split-window'
	for a in "${args[@]}"; do printf ' %q' "$a"; done
	printf '\n'
else
	tmux split-window "${args[@]}"
fi

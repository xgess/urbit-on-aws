#!/bin/bash
set -eo pipefail

# kill the urbit process and the tmux session if 
# either is up
tmux send-keys -t ${TMUX_SESSION_NAME} C-d || true
tmux send-keys -t ${TMUX_SESSION_NAME} C-d || true


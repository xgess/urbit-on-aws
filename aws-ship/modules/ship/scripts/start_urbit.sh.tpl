#!/bin/bash
set -eo pipefail

# install some basic dependencies
sudo apt update
sudo apt install tmux -y

# the EBS volume should already be mounted here
# and if it's not, we want to error
cd /data

# fetch the urbit binary and put it on the EBS volume
sudo mkdir -p /data/urbit
sudo chown -R ${USERNAME}:${USERNAME} /data/urbit
cd /data/urbit
wget --content-disposition https://urbit.org/install/linux-x86_64/latest
tar zxvf ./linux-x86_64.tgz --transform='s/.*/urbit/g'
rm linux-x86_64.tgz

echo "hopping into a tmux session to run the urbit process"
tmux new -d -s ${TMUX_SESSION_NAME} || true
# if urbit is already running, kill it gracefully so we can restart
tmux send-keys -t ${TMUX_SESSION_NAME} C-z
sleep 5
# navigate to the right place
tmux send-keys -t ${TMUX_SESSION_NAME} 'cd /data/urbit' C-m
# if the ship directory is here, run it. otherwise run a comet
if [ -d "/data/urbit/${SHIP}" ]; then
    echo "the ship is here! running it"
    tmux send-keys -t ${TMUX_SESSION_NAME} './urbit ${SHIP}' Enter
elif [ -d "/data/urbit/testcomet" ]; then
    echo "the specified ship isn't here, but there's a comet. running it."
    tmux send-keys -t ${TMUX_SESSION_NAME} './urbit testcomet' Enter
else
    echo "the specified ship is not here. firing up a new comet instead."
    tmux send-keys -t ${TMUX_SESSION_NAME} './urbit -c testcomet' Enter
fi


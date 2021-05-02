#!/bin/bash
set -eo pipefail

sudo apt install jq awscli -y

secret_entry=$(aws --region ${aws_region} secretsmanager get-secret-value --secret-id ${secret_entry_name} | jq '.SecretString | fromjson')
access_key_id=$(echo "$secret_entry" | jq -r '.access_key_id')
secret_access_key=$(echo "$secret_entry" | jq -r '.secret_access_key')
bucket=$(echo "$secret_entry" | jq -r '.bucket')

tmux send-keys -t ${tmux_session_name} ":s3-store|set-endpoint 's3-${aws_region}.amazonaws.com'" Enter
tmux send-keys -t ${tmux_session_name} ":s3-store|set-access-key-id '$access_key_id'" Enter
tmux send-keys -t ${tmux_session_name} ":s3-store|set-secret-access-key '$secret_access_key'" Enter
tmux send-keys -t ${tmux_session_name} ":s3-store|set-current-bucket '$bucket'" Enter


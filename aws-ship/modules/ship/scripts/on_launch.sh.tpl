#!/bin/bash
set -eo pipefail

# REMINDER: this script runs as root when the instance spins up

sudo apt update

# set up the EBS volume and mount it at /data
ebs_volume_details=$(sudo file -s /dev/nvme1n1)
if [ "$ebs_volume_details" = '/dev/nvme1n1: data' ]; then
    echo "brand new EBS volume needs formatting"
    sudo mkfs -t xfs /dev/nvme1n1
fi
sudo mkdir -p /data
sudo mount /dev/nvme1n1 /data

sudo mkdir -p /data/urbit
sudo chown -R ${USERNAME}:${USERNAME} /data/urbit

# ensure we can satisfy the 2G RAM requirements
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab


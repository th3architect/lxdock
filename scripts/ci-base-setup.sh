#!/bin/bash

set -xe

sudo -E apt-get update -q
sudo -E apt-get purge -y lxd lxd-client
sudo -E apt-get install -y snapd
sudo snap install lxd
sudo snap list
sudo lxd --version
sudo snap start lxd

export PATH="/snap/bin:$PATH"

# lxd waitready times out
while [ ! -S /var/snap/lxd/common/lxd/unix.socket ]; do
  sleep 0.5
done

user=`whoami`
sudo usermod -a -G lxd ${user}

sudo lxd init --auto
sudo lxc network create lxdbr0 ipv6.address=none ipv4.address=10.0.3.1/24 ipv4.nat=true
sudo lxc network attach-profile lxdbr0 default eth0

# ansible test needs ssh
if [ ! -f $HOME/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -b 2048 -f $HOME/.ssh/id_rsa -P ""
fi

# allows testing shares with raw.idmap
printf "lxd:$(id -u):1\nroot:$(id -u):1\n" | sudo tee -a /etc/subuid
printf "lxd:$(id -g):1\nroot:$(id -g):1\n" | sudo tee -a /etc/subgid
sudo snap restart lxd

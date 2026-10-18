#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y docker.io curl
systemctl enable --now docker
usermod -aG docker ubuntu

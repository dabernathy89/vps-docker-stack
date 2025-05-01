#!/bin/bash

# This will not work with 1Password SSH keys unless you shut down Docker
# and run the following in the terminal before this script:
# export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
# open -a /Applications/Docker.app

# Build our custom Ansible image with pre-installed collections
echo "Building local Ansible Docker image..."
docker build -t local-ansible-image .

# Run Ansible in a container
echo "Running Ansible in Docker container..."
docker run --rm -it \
  -v "$(pwd):/ansible:ro" \
  -v "$HOME/.ssh/known_hosts:/root/.ssh/known_hosts:ro" \
  -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock \
  -e SSH_AUTH_SOCK="/run/host-services/ssh-auth.sock" \
  -w /ansible \
  local-ansible-image \
  ansible-playbook -i inventory.ini playbook.yml -v -K

# Run with: bash run-ansible.sh
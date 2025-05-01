# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Infrastructure

- Docker-based PHP applications deployed on VPS using Docker Swarm
- Traefik for reverse proxy and SSL termination
- Gantry for container management

## Build Commands

- Build app containers: `docker build -t ghcr.io/USERNAME/frankenphp-app:latest ./app1`
- Deploy app stack: `docker stack deploy --with-registry-auth -c docker-stack.yml app1`
- Provision infrastructure: `ansible-playbook -i inventory playbook.yml`

## Code Style Guidelines

- YAML files: 2-space indentation
- PHP files: 2-space indentation with descriptive header comments
- Docker files: Follow Docker best practices
- File naming: Use lowercase kebab-case for all configuration files
- Ansible: Follow Ansible lint rules for playbooks and roles
- Error handling: Log errors appropriately in PHP applications
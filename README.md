# README: VPS Multi-Service Deployment with Traefik, Swarm, Gantry, and Ansible

This guide outlines the steps to set up a VPS to host multiple web services using Docker Swarm, Traefik as a reverse proxy, Gantry for automated updates, and Ansible for initial server configuration. Each service runs in its own container, defined in separate repositories, and deployed remotely.

## Table of Contents

1.  [Prerequisites](#prerequisites)
    * [Local Machine](#local-machine)
    * [VPS](#vps)
    * [Domains & DNS](#domains--dns)
    * [GitHub & GHCR](#github--ghcr)
2.  [Project Structure (Recommended)](#project-structure-recommended)
3.  [Phase 1: Infrastructure Setup with Ansible](#phase-1-infrastructure-setup-with-ansible)
4.  [Phase 2: Configure Remote Docker Access](#phase-2-configure-remote-docker-access)
5.  [Phase 3: Deploy Core Services (Traefik & Gantry)](#phase-3-deploy-core-services-traefik--gantry)
    * [Deploy Traefik Stack](#deploy-traefik)
    * [Deploy Gantry Stack](#deploy-gantry)
6.  [Phase 4: Deploy Application Services](#phase-4-deploy-application-services)
    * [Build & Push Application Image](#build--push-application-image)
    * [Deploy Application Stack](#deploy-application-stack)
7.  [Phase 5: Updates and Workflow](#phase-5-updates-and-workflow)

---

## Prerequisites

### Local Machine

* **Docker Desktop:** Installed via Homebrew (`brew install --cask docker`) or download from [Docker's website](https://www.docker.com/products/docker-desktop/).
* **SSH Client:** Built into macOS.
* **Git:** Installed via Homebrew (`brew install git`) or macOS Developer Tools.
* **1Password:** With SSH agent enabled for key management.

### VPS

* **Linux Distribution:** A recent version (e.g., Ubuntu 22.04 LTS recommended).
* **SSH Server:** Running and accessible from your local machine.
* **User Account:** A non-root user with `sudo` privileges (`your_deploy_user` in the examples).
* **Firewall:** Configured to allow incoming traffic on ports 22 (SSH), 80 (HTTP), and 443 (HTTPS).

### Domains & DNS

* **Domain Names:** At least one domain name. You'll need subdomains for Traefik (optional, for dashboard) and each service.
    * Example: `traefik.yourdomain.com`, `app1.domain1.com`, `app2.domain2.com`.
* **DNS Records:** `A` records for each (sub)domain pointing to your VPS's public IP address.

### GitHub & GHCR

* **GitHub Account:** To host your code repositories.
* **GitHub Container Registry (GHCR):** Used as the private Docker registry.
* **Personal Access Token (PAT):** Create a GitHub PAT with `read:packages` and `write:packages` scopes. Securely store this token (`YOUR_GITHUB_PAT`).

---

## Project Structure

```
your-project-root/
├── .env                  # GitHub credentials for build-push script
├── .gitignore            # Ignores sensitive .env files
├── build-push.sh         # Script to build and push container images
├── ansible/              # Ansible configuration for the VPS
│   ├── inventory         # Target hosts and variables
│   ├── playbook.yml      # Provisions the VPS
│   ├── ansible.cfg       # Ansible configuration
│   └── run-ansible.sh    # Script to run Ansible in Docker with 1Password
├── core/                 # Combined infrastructure services
│   ├── docker-stack.yml  # Combined Traefik and Gantry stack
│   ├── traefik.yml       # Traefik static configuration
│   ├── gantry-config.yml # Gantry service monitors
│   ├── .env              # Environment variables for both services
│   └── deploy.sh         # Deployment script with context switching
├── app1/                 # First PHP app
│   ├── public/
│   │   └── index.php
│   ├── Dockerfile
│   ├── docker-stack.yml  # App1 stack definition
│   └── deploy.sh         # App1 deployment script
├── app2/                 # Second PHP app
│   ├── public/
│   │   └── index.php
│   ├── Dockerfile
│   ├── docker-stack.yml  # App2 stack definition
│   └── deploy.sh         # App2 deployment script
└── README.md             # This documentation
```
---

## Phase 1: Infrastructure Setup with Ansible

This phase uses Ansible in a Docker container to prepare the **VPS**, eliminating the need to install Ansible locally.

1.  **Navigate** to your `ansible` directory.
2.  **Configure `inventory`:** Set up your VPS IP and SSH user. The SSH key will be provided via 1Password SSH agent.
3.  **Run the Ansible container:**
    ```bash
    # Use the provided helper script that handles 1Password SSH agent forwarding
    ./run-ansible.sh
    ```

    The script will:
    - Mount the 1Password SSH socket into the container
    - Install required Ansible collections and roles inside the container
    - Run the playbook using your 1Password SSH key
    - No need to install Ansible or its dependencies locally!

    This playbook installs Docker, initializes Swarm, and creates the necessary directory for Traefik certificates (`/opt/traefik/letsencrypt`).

---

## Phase 2: Configure Remote Docker Access

Configure your **local Docker client** to manage the Docker Swarm running on the **VPS**.

1.  **Create Docker Context:**
    ```bash
    # Create a named context for your VPS
    docker context create certain-painter --docker "host=ssh://your_deploy_user@your_vps_ip"
    ```
2.  **Switch to Remote Context:**
    ```bash
    docker context use certain-painter
    ```
3.  **Verify Connection (Optional):**
    ```bash
    docker info
    # Should show "Swarm: active" and details from your VPS Docker daemon
    ```
    *All subsequent `docker` commands in this terminal session will target the remote VPS Swarm.*

---

## Phase 3: Deploy Core Services (Traefik & Gantry)

Deploy the essential Traefik proxy and Gantry update monitor from your **local machine** using a combined configuration.

### Deploy Combined Core Stack

1.  **Navigate** to your `core` directory.
2.  **Review `.env`:** Set these variables:
    * `LETSENCRYPT_EMAIL` - Your email for Let's Encrypt certificates
    * `GHCR_USER` and `GHCR_PAT` - Your GitHub username and Personal Access Token
3.  **Review Configuration Files:**
    * `traefik.yml` - Traefik's static configuration
    * `gantry-config.yml` - Services Gantry should monitor
    * `docker-stack.yml` - Combined stack definition for both services
4.  **Deploy:**
    ```bash
    # Run the deployment script
    ./deploy.sh

    # Or manually deploy with:
    # export $(grep -v '^#' .env | xargs)
    # docker stack deploy -c docker-stack.yml core
    ```
5.  **Verify:**
    * Check services: `docker service ls`
    * Check Traefik logs: `docker service logs core_traefik`
    * Check Gantry logs: `docker service logs core_gantry`
    * Access the Traefik dashboard at your configured domain

---

## Phase 4: Deploy Application Services

Deploy your individual applications (e.g., `app1`, `app2`) from your **local machine**. Repeat these steps for each application.

### Build & Push Application Image

1.  **Configure authentication** by setting up your GitHub credentials:
    ```bash
    # Edit the .env file in the project root
    GITHUB_USER=your-github-username
    GITHUB_PAT=your-github-personal-access-token
    ```

2.  **Run the build-push script** with the app name:
    ```bash
    # From the project root
    ./build-push.sh app1
    ```

    This script:
    - Loads your GitHub credentials from .env
    - Authenticates with GitHub Container Registry
    - Builds the app image with the correct naming convention
    - Pushes it to GitHub Container Registry
    - Shows you the next steps

### Deploy Application Stack

1.  **Navigate** to the application's directory (e.g., `app1`).
2.  **Review `docker-stack.yml`:**
    * Verify the `image` name matches the one you pushed.
    * Ensure it connects to the external `traefik-public` network.
    * Check Traefik labels (`traefik.enable=true`, `traefik.docker.network`, `rule=Host(...)`, `loadbalancer.server.port`). **Update the `Host` rule** to the correct domain/subdomain for this app.
3.  **Deploy:** Use the deployment script to ensure the correct Docker context.
    ```bash
    # Ensure Docker context is correct and deploy the stack
    ./deploy.sh
    ```
4.  **Verify:**
    * Check Swarm service status: `docker service ls` (look for `app1_app`).
    * Check service logs: `docker service logs app1_app`.
    * Wait a minute for Traefik to detect the service and for Let's Encrypt to issue a certificate, then access the application via its domain (`https://app1.domain1.com`).

---

## Phase 5: Updates and Workflow

1.  **Make Code Changes:** Modify the code within an application's repository (e.g., `app1`).

2.  **Build & Push New Image:** Use the build-push script to rebuild and push the updated image:
    ```bash
    # From the project root
    ./build-push.sh app1
    ```

3.  **Automatic Update:** Gantry (running on the VPS) periodically checks GHCR. When it detects that the digest for the `ghcr.io/dabernathy89/php-test-app1:latest` image has changed, it will automatically trigger a `docker service update app1_app --image ... --with-registry-auth` command on the Swarm manager.

4.  **Swarm Rolling Update:** Docker Swarm performs a rolling update according to the `update_config` defined in the application's `docker-stack.yml`.

5.  **Monitor:** Check service logs to observe the update process:
    ```bash
    # Switch to correct Docker context if needed
    docker context use certain-painter

    # Check Gantry logs
    docker service logs core_gantry

    # Check application logs
    docker service logs app1_app
    ```

---

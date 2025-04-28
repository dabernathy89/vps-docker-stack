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

* **Ansible:** Installed (`pip install ansible`).
* **Docker Engine:** Installed (to build images and run remote commands).
* **SSH Client:** Access to the VPS via SSH (key-based authentication recommended).
* **Git:** To manage your code repositories.
* **Ansible Docker Role & Collection:**
    * `ansible-galaxy install geerlingguy.docker -p ./roles/` (Run inside your Ansible project dir)
    * `ansible-galaxy collection install community.docker`
* **Python Docker SDK:** Required by Ansible Docker modules (`pip install docker`).

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

## Project Structure (Recommended)

Organize your code locally for clarity:

your-project-root/├── ansible/      # Ansible configuration for the VPS│   ├── playbook.yml│   ├── inventory│   ├── requirements.yml│   ├── gantry_config.yml   # Gantry config file (copied by Ansible)│   └── roles/│       └── geerlingguy.docker/ # Installed via ansible-galaxy│├── traefik/          # Traefik deployment files│   ├── docker-stack.yml│   ├── traefik.yml│   └── .env                # Contains LETSENCRYPT_EMAIL│├── gantry/           # Gantry deployment files│   ├── docker-stack.yml│   └── .env                # Contains GHCR_USER, GHCR_PAT│├── frankenphp-app1/        # Repository for your first PHP app│   ├── public/│   │   └── index.php│   ├── Dockerfile│   └── docker-stack.yml    # Defines app1 stack│├── frankenphp-app2/        # Repository for your second PHP app│   ├── public/│   │   └── index.php│   ├── Dockerfile│   └── docker-stack.yml    # Defines app2 stack│└── README.md               # This file
---

## Phase 1: Infrastructure Setup with Ansible

This phase uses Ansible on your **local machine** to prepare the **VPS**.

1.  **Navigate** to your `ansible` directory.
2.  **Configure `inventory`:** Add your VPS IP, SSH user, and path to your SSH private key. Set the `deploy_user` variable.
3.  **Configure `gantry_config.yml`:** Define the services Gantry should monitor (e.g., `app1_app`, `app2_app`) and specify the image names and tags. Set `pass_credentials_to_env: true` for `ghcr.io`.
4.  **Ensure Roles/Collections Installed:** Run the `ansible-galaxy` commands mentioned in the prerequisites if you haven't already.
5.  **Run the Playbook:**
    ```bash
    ansible-playbook -i inventory playbook.yml
    ```
    This installs Docker, initializes Swarm, creates necessary directories (`/opt/traefik/letsencrypt`, `/opt/gantry/config`), and copies `gantry_config.yml` to the VPS.

---

## Phase 2: Configure Remote Docker Access

Configure your **local Docker client** to manage the Docker Swarm running on the **VPS**.

1.  **Create Docker Context:**
    ```bash
    # Replace with your actual deploy user and VPS IP
    docker context create swarm-vps --docker "host=ssh://your_deploy_user@your_vps_ip"
    ```
2.  **Switch to Remote Context:**
    ```bash
    docker context use swarm-vps
    ```
3.  **Verify Connection (Optional):**
    ```bash
    docker info
    # Should show "Swarm: active" and details from your VPS Docker daemon
    ```
    *All subsequent `docker` commands in this terminal session will target the remote VPS Swarm.*

---

## Phase 3: Deploy Core Services (Traefik & Gantry)

Deploy the essential Traefik proxy and Gantry update monitor from your **local machine**.

### Deploy Traefik Stack

1.  **Navigate** to your `traefik` directory.
2.  **Create/Review `.env`:** Ensure `LETSENCRYPT_EMAIL` is set correctly.
3.  **Review `traefik.yml`:** Verify static configuration (entrypoints, ACME resolver, Docker provider).
4.  **Review `docker-stack.yml`:** Check image version, volumes, network, placement constraints, and dashboard labels (update `Host` rule if enabling).
5.  **Deploy:**
    ```bash
    # No registry auth needed if using official Traefik image
    docker stack deploy -c docker-stack.yml traefik
    ```
6.  **Verify:** Check Traefik logs (`docker service logs traefik_traefik`) and try accessing the dashboard URL (if configured).

### Deploy Gantry Stack

1.  **Navigate** to your `gantry` directory.
2.  **Create/Review `.env`:** Set your `GHCR_USER` and `GHCR_PAT`.
3.  **Review `docker-stack.yml`:** Check image, environment variables (for credentials), volumes (Docker socket, config file), and placement constraints.
4.  **Export Environment Variables** (for `docker stack deploy` to access them):
    ```bash
    # Ensure you are in the gantry directory
    export $(grep -v '^#' .env | xargs)
    ```
    *(Alternatively, manually export `GHCR_USER` and `GHCR_PAT`)*
5.  **Deploy:**
    ```bash
    # --with-registry-auth sends GHCR credentials for pulling Gantry image if needed,
    # and Gantry itself uses the ENV vars to auth later when checking app images.
    docker stack deploy --with-registry-auth -c docker-stack.yml gantry
    ```
6.  **Verify:** Check Gantry logs (`docker service logs gantry_gantry`). It should start monitoring based on `/opt/gantry/config/config.yml`.

---

## Phase 4: Deploy Application Services

Deploy your individual applications (e.g., `frankenphp-app1`, `frankenphp-app2`) from your **local machine**. Repeat these steps for each application.

### Build & Push Application Image

1.  **Navigate** to the application's directory (e.g., `frankenphp-app1`).
2.  **Build the Image:** Replace placeholders with your GHCR username and app name.
    ```bash
    docker build -t ghcr.io/YOUR_GITHUB_USERNAME/frankenphp-app1:latest .
    # Optional: Tag with a version
    # docker tag ghcr.io/YOUR_GITHUB_USERNAME/frankenphp-app1:latest ghcr.io/YOUR_GITHUB_USERNAME/frankenphp-app1:v1.0.0
    ```
3.  **Log in to GHCR** (if not already logged in the current session):
    ```bash
    echo $YOUR_GITHUB_PAT | docker login ghcr.io -u $YOUR_GITHUB_USERNAME --password-stdin
    ```
4.  **Push the Image:**
    ```bash
    docker push ghcr.io/YOUR_GITHUB_USERNAME/frankenphp-app1:latest
    # Optional: Push version tag
    # docker push ghcr.io/YOUR_GITHUB_USERNAME/frankenphp-app1:v1.0.0
    ```

### Deploy Application Stack

1.  **Navigate** to the application's directory (e.g., `frankenphp-app1`).
2.  **Review `docker-stack.yml`:**
    * Verify the `image` name matches the one you pushed.
    * Ensure it connects to the external `traefik-public` network.
    * Check Traefik labels (`traefik.enable=true`, `traefik.docker.network`, `rule=Host(...)`, `loadbalancer.server.port`). **Update the `Host` rule** to the correct domain/subdomain for this app.
3.  **Deploy:** Use a unique stack name (e.g., `app1`).
    ```bash
    # --with-registry-auth is needed for Swarm to pull your private image
    docker stack deploy --with-registry-auth -c docker-stack.yml app1
    ```
4.  **Verify:**
    * Check Swarm service status: `docker service ls` (look for `app1_app`).
    * Check service logs: `docker service logs app1_app`.
    * Wait a minute for Traefik to detect the service and for Let's Encrypt to issue a certificate, then access the application via its domain (`https://app1.domain1.com`).

---

## Phase 5: Updates and Workflow

1.  **Make Code Changes:** Modify the code within an application's repository (e.g., `frankenphp-app1`).
2.  **Build & Push New Image:** Re-run the build and push steps (**using the same image tag that Gantry is configured to monitor**, e.g., `:latest`).
    ```bash
    cd path/to/frankenphp-app1
    docker build -t ghcr.io/YOUR_GITHUB_USERNAME/frankenphp-app1:latest .
    docker push ghcr.io/YOUR_GITHUB_USERNAME/frankenphp-app1:latest
    ```
3.  **Automatic Update:** Gantry (running on the VPS) periodically checks GHCR. When it detects that the digest for the `ghcr.io/YOUR_GITHUB_USERNAME/frankenphp-app1:latest` image has changed, it will automatically trigger a `docker service update app1_app --image ... --with-registry-auth` command on the Swarm manager.
4.  **Swarm Rolling Update:** Docker Swarm performs a rolling update according to the `update_config` defined in the application's `docker-stack.yml`.
5.  **Monitor:** Check Gantry logs (`docker service logs gantry_gantry`) and the application service logs (`docker service logs app1_app`) on the VPS (using the remote context or SSH) to observe the update process.

---

# FLTR Hub

Centralized instance for managing the FLTR nodes, aggregating logs, and communicating with the FLTR app.

### Prerequisites

1. Purchase a domain name
2. On a secure device, generate your own Ed25519 SSH key pair: `ssh-keygen -t ed25519`
3. Create an Alpine Linux compute instance with a static public IPv4 address
4. If you're running within a container or virtual cloud network, expose or add ingress rules for TCP ports 22, 80, 443, 8080, and 8443
5. Create a DNS A record pointing your static public IPv4 address to your domain or a new subdomain (may take up to a day to propagate)

### Installation

1. SSH into the Alpine Linux instance as root
2. Install bash (`apk add bash`)
3. Download the `fltr-hub-setup.bash` and `fltr-hub-setup.conf.template` files
4. Rename the `fltr-hub-setup.conf.template` file to `fltr-hub-setup.conf` and edit with your values
5. Run `bash fltr-hub-setup.bash`
6. Verify Emitter is running by browsing to https://YOUR-DOMAIN-HERE/keygen
7. Verify Headscale is running by browsing to https://YOUR-DOMAIN-HERE:8443/windows

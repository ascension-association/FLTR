# FLTR Node

Internet exit node for end user devices

### Prerequisites

1. Create a FLTR Hub instance (see `hub` folder in this repo)
2. Login to the FLTR Hub instance and create a user: `headscale user create user1`
3. Generate an autorization key valid for one hour: `headscale preauthkeys create -e 1h --user user1`
4. Create an Alpine Linux compute instance with a public IPv4 address
5. If you're running within a container or virtual cloud network, expose or add an ingress rule for stateless UDP port 41641

### Installation

1. SSH into the Alpine Linux instance as root
2. Install bash (`apk add bash`)
3. Download the `fltr-node-setup.bash` and `fltr-node-setup.conf.template` files
4. Rename the `fltr-node-setup.conf.template` file to `fltr-node-setup.conf` and edit with your values
5. Run `bash fltr-node-setup.bash`
6. Connect to the exit node using a Tailscale client and try to browse to `example.net` (should be blocked, whereas `example.com` should load)

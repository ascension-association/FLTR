#!/bin/bash

# load configuration settings
while read LINE; do declare "$LINE"; done <fltr-hub-setup.conf

# verify root
if [ "${EUID}" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# verify SSH key
if [[ -z "${ED25519_PUB_KEY}" ]] || [[ "${ED25519_PUB_KEY}" != "ssh-ed25519 "* ]]; then
  echo 'Missing Ed25519 public key. Create one via `ssh-keygen -t ed25519` and enter the public key in fltr-hub-setup.conf'
  exit
fi

# verify domain name
if [[ -z "${DOMAIN_NAME}" ]] || [[ "${DOMAIN_NAME}" != *"."* ]]; then
  echo 'Missing domain name. Please see README for instructions.'
  exit
fi

# verify email
if [[ -z "${ACME_EMAIL}" ]] || [[ "${ACME_EMAIL}" != *"@"* ]]; then
  echo "Missing email address, which is required by Let's Encrypt. Please see README for instructions."
  exit
fi

# use SafeSurfer.io upstream DNS servers
sed -i "/^nameserver.*$/d" /etc/resolv.conf
echo "nameserver 104.197.28.121" >>/etc/resolv.conf
echo "nameserver 104.155.237.225" >>/etc/resolv.conf

# enable community repo and use TLS
sed -i "s/#//" /etc/apk/repositories
sed -i "s/^http:/https:/g" /etc/apk/repositories
apk update

# enable automatic updates
if [ "$(apk list --installed | grep apk-autoupdate | wc -l)" -eq 0 ]; then
  echo "Enabling automatic updates..."
  apk add apk-autoupdate --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing
  cat >>/etc/apk/autoupdate.conf <<EOF

after_upgrade() {
  for pkg in \$@; do
    case \$pkg in
      linux-*) reboot;;
    esac
  done
}
EOF

  cat >/etc/periodic/daily/apk-autoupdate.sh <<EOF
#!/bin/sh
set -eu
apk-autoupdate
EOF

  chmod 700 /etc/periodic/daily/apk-autoupdate.sh
fi

# install tinyssh
if [ "$(apk list --installed | grep tinyssh | wc -l)" -eq 0 ]; then
  echo "Installing tinyssh..."
  apk del openssh dropbear
  apk add tinyssh
  rc-update add tinysshd
  mkdir -p ~/.ssh
  echo "${ED25519_PUB_KEY}" >~/.ssh/authorized_keys
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/authorized_keys
  rc-service tinysshd start
fi

# disable IPv6
echo 1 >/proc/sys/net/ipv6/conf/all/disable_ipv6

# install Endwall
if [ ! -f /usr/local/bin/endwall ]; then
  echo "Installing endwall..."
  apk del iptables ip6tables
  apk add curl nftables iproute2 nmap
  rc-update add nftables
  rc-service nftables start
  curl -sLo /usr/local/bin/endwall https://raw.githubusercontent.com/ascension-association/endwall/master/endwall_nft_alpine.sh
  sed -i "s/#server_in tcp 22/server_in tcp 22/" /usr/local/bin/endwall
  sed -i "s/#server_in_x tcp 80,443/server_in_x tcp 80,443/" /usr/local/bin/endwall
  sed -i "s/#server_in_x tcp 80,443/server_in_x tcp 80,443/" /usr/local/bin/endwall
  chmod u+wrx /usr/local/bin/endwall
  /usr/local/bin/endwall
fi

# install Headscale
apk add headscale --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing
echo '{"acls":[{"action":"accept","src":["*"],"dst":["*:*"]}]}' >/etc/headscale/acl.hujson
chmod 644 /etc/headscale/acl.hujson
sed -i "s/^server_url.*$/server_url: https:\/\/${DOMAIN_NAME}:443/" /etc/headscale/config.yaml
sed -i "s/^listen_addr.*$/listen_addr: 0.0.0.0:443/" /etc/headscale/config.yaml
sed -i "s/^acme_email.*$/acme_email: \"${ACME_EMAIL}\"/" /etc/headscale/config.yaml
sed -i "s/^tls_letsencrypt_hostname.*$/tls_letsencrypt_hostname: \"${DOMAIN_NAME}\"/" /etc/headscale/config.yaml
sed -i "s/^acl_policy_path.*$/acl_policy_path: \"\/etc\/headscale\/acl.hujson\"/" /etc/headscale/config.yaml
sed -i "s/base_domain: example\.com/base_domain: ${DOMAIN_NAME}/" /etc/headscale/config.yaml
sed -i "s/magic_dns: true/magic_dns: false/" /etc/headscale/config.yaml
sed -i "s/override_local_dns: false/override_local_dns: true/" /etc/headscale/config.yaml
sed -i "s/^    - 1\.1\.1\.1.*$/    - 104.197.28.121/" /etc/headscale/config.yaml
sed -i "/104\.197\.28\.121/a \    \- 104.155.237.225" /etc/headscale/config.yaml
# need to run as root due to privileged 443 port
sed -i "s/^command_user=.*/command_user=\"root:root\"/" /etc/init.d/headscale
rc-update add headscale
rc-service headscale start

exit

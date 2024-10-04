#!/bin/bash

# set time to UTC
apt-get install -y dbus
systemctl start dbus && systemctl enable dbus
timedatectl set-timezone UTC
systemctl restart systemd-timesyncd

# allow routing
echo "net.ipv4.ip_forward = 1" >>/etc/sysctl.d/local.conf
sysctl -p /etc/sysctl.d/local.conf

# increase file limits
echo "fs.nr_open=4194304" >>/etc/sysctl.d/local.conf
sysctl -p /etc/sysctl.d/local.conf
ulimit -n 4194304
sed -i "s/# End of file//" /etc/security/limits.conf
printf "\n* - nofile 4194304\nroot - nofile 4194304\n" >>/etc/security/limits.conf

# optimize kernel
cat >>/etc/sysctl.d/local.conf <<EOF
net.core.somaxconn = 1024
net.core.netdev_max_backlog = 5000
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_wmem = 4096 12582912 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_max_syn_backlog = 8096
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
EOF

sysctl -p /etc/sysctl.d/local.conf

# install latest version of Go (newer than the Debian apt-get repo)
dietpi-software install 188

# install nft-blackhole (IP address blocking)
apt-get install -y nftables python3 python-is-python3 python3-jinja2 python3-yaml python3-systemd systemd curl

mkdir -p /usr/local/share/nft-blackhole
curl -sLo /usr/local/bin/nft-blackhole.py https://raw.githubusercontent.com/ascension-association/nft-blackhole/refs/heads/main/nft-blackhole.py
curl -sLo /usr/local/share/nft-blackhole/nft-blackhole.j2 https://raw.githubusercontent.com/ascension-association/nft-blackhole/refs/heads/main/nft-blackhole.j2
curl -sLo /usr/local/etc/nft-blackhole.yaml https://raw.githubusercontent.com/ascension-association/nft-blackhole/refs/heads/main/nft-blackhole.yaml
curl -sLo /usr/lib/systemd/system/nft-blackhole.service https://raw.githubusercontent.com/ascension-association/nft-blackhole/refs/heads/main/nft-blackhole.service
curl -sLo /usr/lib/systemd/system/nft-blackhole-reload.service https://raw.githubusercontent.com/ascension-association/nft-blackhole/refs/heads/main/nft-blackhole-reload.service
curl -sLo /usr/lib/systemd/system/nft-blackhole-reload.timer https://raw.githubusercontent.com/ascension-association/nft-blackhole/refs/heads/main/nft-blackhole-reload.timer

chmod +x /usr/local/bin/nft-blackhole.py

sed -i 's/v6: on/v6: off/' /usr/local/etc/nft-blackhole.yaml

sed -i 's/- 192\.168\.0\.1\/24/- 192.168.0.0\/16/' /usr/local/etc/nft-blackhole.yaml
sed -i '/- 127.0.0.1/a \    - 10.0.0.0/8' /usr/local/etc/nft-blackhole.yaml
sed -i '/- 127.0.0.1/a \    - 172.16.0.0/12' /usr/local/etc/nft-blackhole.yaml
sed -i '/- 127.0.0.1/a \    - 100.64.0.0/10' /usr/local/etc/nft-blackhole.yaml
sed -i '/- 127.0.0.1/a \    - 104.197.28.121' /usr/local/etc/nft-blackhole.yaml
sed -i '/- 127.0.0.1/a \    - 104.155.237.225' /usr/local/etc/nft-blackhole.yaml

sed -i 's/https:\/\/iplists\.firehol\.org\/files\/bi_any_0_1d\.ipset/https:\/\/raw.githubusercontent.com\/dibdot\/DoH-IP-blocklists\/master\/doh-ipv4.txt/' /usr/local/etc/nft-blackhole.yaml
sed -i 's/https:\/\/iplists\.firehol\.org\/files\/haley_ssh\.ipset/https:\/\/raw.githubusercontent.com\/ascension-association\/FLTR\/main\/node\/dufcxgnbjsdwmwctgfuj-iblocklist-pedophiles-mirror.txt/' /usr/local/etc/nft-blackhole.yaml
sed -i 's/firehol_level2\.netset/firehol_level1.netset/' /usr/local/etc/nft-blackhole.yaml
#sed -i '/firehol_level1/a \    - https://iplists.firehol.org/files/firehol_anonymous.netset' /usr/local/etc/nft-blackhole.yaml

# https://www.bis.doc.gov/index.php/policy-guidance/country-guidance/sanctioned-destinations
sed -i 's/- cn/- cu/' /usr/local/etc/nft-blackhole.yaml
sed -i '/- cu/a \  - ir' /usr/local/etc/nft-blackhole.yaml
sed -i '/- cu/a \  - kp' /usr/local/etc/nft-blackhole.yaml
sed -i '/- cu/a \  - sy' /usr/local/etc/nft-blackhole.yaml

systemctl start nft-blackhole.service && systemctl enable nft-blackhole.service && systemctl enable --now nft-blackhole-reload.timer

# install Blocky, including SafeSurfer.io upstream DNS servers (domain name blocking)
cd /tmp
curl -sLo blocky.tar.gz https://github.com/0xERR0R/blocky/releases/download/v0.24/blocky_v0.24_Linux_arm64.tar.gz
tar -xf blocky.tar.gz
mv blocky /usr/local/bin
mkdir /etc/blocky
cat >/etc/blocky/config.yml <<EOF
upstreams:
  groups:
    default:
      - 104.197.28.121
      - 104.155.237.225
filtering:
  queryTypes:
    - AAAA
blocking:
  denylists:
    adult:
      - https://nsfw.oisd.nl/domainswild
    ads:
      - https://small.oisd.nl/domainswild
    custom:
      - |
        # inline definition with YAML literal block scalar style
        baddomain.org
        tor.bravesoftware.com
        odoh.cloudflare-dns.com
        odoh1.surfdomeinen.nl
        dweb.link
        nftstorage.link
  allowlists:
    custom:
      - |
        # inline definition with YAML literal block scalar style
        doh.safesurfer.io
        www.yahoo.com
        assets.msn.com
        vecpea.com
        zzztest.oisd.nl
  clientGroupsBlock:
    default:
      - adult
      - ads
      - custom
caching:
  minTime: 5m
ports:
  dns: 53
EOF

# run Blocky
cat >/etc/systemd/system/blocky.service <<EOF
[Unit]
Description=Blocky
After=network.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/local/bin/blocky serve --config /etc/blocky/config.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl start blocky && systemctl enable blocky

# enable DHCP starvation
apt-get install -y screen git cmake zlib1g-dev build-essential
cd /tmp
git clone https://github.com/jacopodl/dstar
cd dstar
sed -i '/branch =/d' ./.gitmodules
git submodule update --init --recursive --remote
cmake .
make
mv ./bin/dstar /usr/local/bin
apt-get purge -y --auto-remove cmake zlib1g-dev build-essential

cat >/root/dstar.sh <<EOF
#!/bin/bash
/usr/bin/screen -Dm /usr/local/bin/dstar \$(ip route get 104.197.28.121 | grep -oP ' dev \K\S+') --starvation --server --dns \$(ip addr show \$(ip route get 104.197.28.121 | grep -oP ' dev \K\S+') | grep 'inet\b' | awk '{print \$2}' | cut -d/ -f1)
EOF

chmod +x /root/dstar.sh
cat >/etc/systemd/system/dstar.service <<EOF
[Unit]
Description=dstar
After=network.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/root/dstar.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl start dstar && systemctl enable dstar

# enable ARP spoof
apt-get install -y dsniff
cat >/root/arpspoof.sh <<EOF
#!/bin/bash
/usr/bin/screen -Dm /usr/sbin/arpspoof -i $(ip route get 104.197.28.121 | grep -oP ' dev \K\S+') \$(ip r | grep '^default' | cut -d' ' -f3)
EOF

chmod +x /root/arpspoof.sh
cat >/etc/systemd/system/arpspoof.service <<EOF
[Unit]
Description=arpspoof
After=network.target

[Service]
User=root
Group=root
Type=simple
ExecStart=/root/arpspoof.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl start arpspoof && systemctl enable arpspoof

# force local DNS
apt-get install resolvconf -y
echo "nameserver 127.0.0.1" >/etc/resolv.conf
sed -i 's/#prepend\sdomain-name-servers.*/prepend domain-name-servers 127.0.0.1;/' /etc/dhcp/dhclient.conf
>/etc/resolvconf/resolv.conf.d/head
>/etc/resolvconf/resolv.conf.d/tail

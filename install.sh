#!/bin/bash

#1  Compile
go build
#2. Copy binary to /usr/local/bin
sudo install --owner=root --group=root --mode=755 \
             ./proxmox-service-discovery \
             /usr/local/bin/ns-prox
             
#3. Copy env to /usr/local/etc
# Expect ns-prox.env to be present in .ssh dorectory
sops decrypt ./secrets/ns-prox.enc.env >/tmp/ns-prox/env
sudo install --owner=root --group=root --mode=644 \
             /tmp/ns-prox.env \
             /usr/local/etc/ns-prox.env
rm -f /tmp/ns-prox.env
#4. Copy systemd unit to /etc/systemd/system
cat <<'EOF' >/tmp/ns-prox.service 
[Unit]
Description=Proxmox Service Discovery
After=network.target

[Service]
EnvironmentFile=/usr/local/etc/ns-prox.env
ExecStart=/usr/local/bin/ns-prox \
  --proxmox-host=${PROXMOX_NODE} \
  --proxmox-user=${PROXMOX_USER} \
  --proxmox-token-id=${PROXMOX_TOKEN_ID} \
  --proxmox-token-secret=${PROXMOX_TOKEN_SECRET} \
  --addr=:53 \
  --debug-addr=:8080 \
  --dns-zone=${DOMAIN} \
  --filter-exclude-tags=nodns
Restart=on-failure
User=nobody
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

sudo install --owner=root --group=root --mode=644 \
             /tmp/ns-prox.service \
             /etc/systemd/system/ns-prox.service

#5. Configure system resolver
sudo mkdir -p /etc/systemd/resolved.conf.d
cat <<'EOF' >/tmp/resolved.conf 
[Resolve]
DNS=172.19.1.3 172.19.1.4
DNSStubListener=no
EOF
sudo install --owner=root --group=root --mode=644 \
             /tmp/resolved.conf \
             /etc/systemd/resolved.conf.d/

#5. start Service

sudo systemctl daemon-reload
sudo systemctl restart systemd-resolved.service
sudo systemctl restart ns-prox.service

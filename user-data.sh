#!/usr/bin/env bash

# Do not change these variables
# You can specify binary versions in the terraform.tfvars file

VAULTDOWNLOAD=https://releases.hashicorp.com/vault/${VAULTVERSION}/vault_${VAULTVERSION}_linux_amd64.zip
VAULTCONFIGDIR=/etc/vault.d

CONSULDOWNLOAD=https://releases.hashicorp.com/consul/${CONSULVERSION}/consul_${CONSULVERSION}_linux_amd64.zip

apt install -y unzip

# Downloading binaries and creating Vault config

curl -L $VAULTDOWNLOAD > vault.zip
unzip vault.zip -d /usr/local/bin
mkdir -p $VAULTCONFIGDIR

cat <<EOF > $VAULTCONFIGDIR/vault.hcl
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
}

listener "tcp" {
 address     = "127.0.0.1:8200"
 tls_disable = 1
}
EOF

curl -L $CONSULDOWNLOAD > consul.zip
unzip consul.zip -d /usr/local/bin

# systemd unit files

cat <<EOF > /etc/systemd/system/vault.service
[Unit]
Description=Vault Agent
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
ExecStart=/usr/local/bin/vault server -config="/etc/vault.d/vault.hcl"
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/systemd/system/consul.service
[Unit]
Description=Consul Agent
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
ExecStart=/usr/local/bin/consul agent -dev
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# reload systemd

systemctl daemon-reload

# set environment variable

echo "export VAULT_ADDR=http://127.0.0.1:8200" >> /root/.bashrc
echo "export VAULT_ADDR=http://127.0.0.1:8200" >> /home/ubuntu/.bashrc
# enable and start services

systemctl enable vault
systemctl enable consul

systemctl start consul
systemctl start vault

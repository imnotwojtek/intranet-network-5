#!/bin/bash

# Usunięcie Pi-hole i aktualizacja systemu
pihole uninstall --unattended
sudo apt update && sudo apt upgrade -y

# Instalacja NGINX
sudo apt install -y nginx

# Instalacja i konfiguracja WireGuard
sudo apt install -y wireguard
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
echo "[Interface]
PrivateKey = $(sudo cat /etc/wireguard/privatekey)
Address = 10.0.0.1/24
ListenPort = 51820
" | sudo tee /etc/wireguard/wg0.conf
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Instalacja wg-dashboard
sudo apt install -y git python3 python3-pip
git clone https://github.com/Place1/wg-access-server.git
cd wg-access-server
./build.sh
sudo ./wg-access-server --config ./config.yaml &

# Konfiguracja NGINX dla stron wgx
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt -subj "/CN=wgx"
for site in help helpdesk data; do
  echo "server {
    listen 80;
    server_name $site.wgx;
    location / {
      return 301 https://\$host\$request_uri;
    }
  }
  server {
    listen 443 ssl;
    server_name $site.wgx;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    location / {
      return 200 'hello $site';
    }
  }" | sudo tee /etc/nginx/sites-available/$site.wgx
  sudo ln -s /etc/nginx/sites-available/$site.wgx /etc/nginx/sites-enabled/
done
sudo nginx -s reload

echo "Zakończono konfigurację. Twój system jest teraz gotowy do użycia."

#!/bin/bash

# Install dependencies
sudo apt update
sudo apt install -y nginx wireguard php8.2-fpm mysql-server phpmyadmin wp-cli

# Create directories
sudo mkdir -p /etc/nginx/ssl
sudo mkdir -p /var/www

# WireGuard Configuration
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
random_port=$(shuf -i 20000-65000 -n 1)
echo "WireGuard Port: $random_port" >> /root/wg_port.txt
echo "[Interface]
PrivateKey = $(sudo cat /etc/wireguard/privatekey)
Address = 10.0.0.1/24
ListenPort = $random_port
" | sudo tee /etc/wireguard/wg0.conf
sudo systemctl enable wg-quick@wg0 && sudo systemctl start wg-quick@wg0

# SSL Configuration
sudo openssl ecparam -genkey -name secp384r1 | sudo tee /etc/nginx/ssl/nginx.key
sudo openssl req -x509 -nodes -days 1825 -key /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt -subj "/CN=wgx"

# NGINX, MySQL, and WordPress Configuration
for i in {1..8}; do
  domain=$(shuf -zer -n6 {a..z}{A..Z}{0..9})
  db_name=$(shuf -zer -n6 {a..z}{A..Z}{0..9})
  db_user=$(shuf -zer -n6 {a..z}{A..Z}{0..9})
  db_pass=$(openssl rand -base64 12 | tr -d /=+)
  echo "127.0.0.1 $domain.wg" >> /etc/hosts
  echo "$domain | $db_name | $db_user | $db_pass" >> /root/site_info.txt
  sudo mysql -e "CREATE DATABASE $db_name; GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost' IDENTIFIED BY '$db_pass'; FLUSH PRIVILEGES;"
  wp core download --path=/var/www/$domain --allow-root
  wp config create --path=/var/www/$domain --dbname=$db_name --dbuser=$db_user --dbpass=$db_pass --dbhost=localhost --allow-root
  wp core install --path=/var/www/$domain --url="$domain.wg" --title="$domain Site" --admin_user="$db_user" --admin_password="$db_pass" --admin_email="admin@$domain.wg" --allow-root
done

# DNS and Network Configuration
echo "nameserver 1.1.1.1
nameserver 1.0.0.1" | sudo tee /etc/resolv.conf
sudo systemctl restart networking

# VPN Management Password
vpn_pass=$(openssl rand -base64 32)
echo "VPN Management Password: $vpn_pass" >> /root/vpn_password.txt

# WireGuard Client Configuration
for i in {1..10}; do
  client_id="CLIENT-$(shuf -zer -n6 {A..Z}{a..z}{0..9})"
  echo "Client ID: $client_id" >> /root/wg_clients.txt
done

echo "Configuration complete. Your system is now ready for use."

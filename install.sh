#!/bin/bash

sudo apt install -y nginx wireguard php-fpm mysql-server phpmyadmin

# Konfiguracja WireGuard
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
echo "[Interface]
PrivateKey = $(sudo cat /etc/wireguard/privatekey)
Address = 10.0.0.1/24
ListenPort = 51820
" | sudo tee /etc/wireguard/wg0.conf
sudo systemctl enable wg-quick@wg0 && sudo systemctl start wg-quick@wg0

# Konfiguracja SSL dla MySQL i NGINX
sudo openssl ecparam -genkey -name secp384r1 | sudo tee /etc/nginx/ssl/nginx.key
sudo openssl req -x509 -nodes -days 1825 -key /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt -subj "/CN=wgx"

# Konfiguracja NGINX i domen
for domain in wgx wg wo; do
  sudo wget https://wordpress.org/latest.tar.gz && tar xzf latest.tar.gz
  echo "server {
    listen 443 ssl;
    server_name *.$domain;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    root /var/www/$domain;
    index index.php;
    location / {
      try_files \$uri \$uri/ /index.php?\$args;
    }
    location ~ \.php$ {
      include snippets/fastcgi-php.conf;
      fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }
  }" | sudo tee /etc/nginx/sites-available/$domain
  sudo ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
done

# Konfiguracja MySQL
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'root'; FLUSH PRIVILEGES;"
sudo mysql -e "CREATE DATABASE wordpress; GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY 'password'; FLUSH PRIVILEGES;"

# Usunięcie i odświeżenie cache
sudo apt clean && sudo systemd-resolve --flush-caches

# Losowe hasło do zarządzania VPN
password=$(openssl rand -base64 32)
echo "Hasło do zarządzania VPN: $password"

echo "Zakończono konfigurację. Twój system jest teraz gotowy do użycia."

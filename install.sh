#!/bin/bash

# Aktualizacja i instalacja Pi-hole
sudo apt update -y && sudo apt upgrade -y && echo "yes" | sudo curl -sSL https://install.pi-hole.net | bash

# Sprawdzenie i instalacja htop
if ! command -v htop &> /dev/null; then
    sudo apt install -y htop
fi

# Instalacja iftop
sudo apt install -y iftop

# Tworzenie i konfiguracja 2GB pliku swap
sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Zmiana serwera DNS
echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" | sudo tee /etc/resolv.conf > /dev/null

# Restart usług
sudo service networking restart

echo "Zakończono konfigurację. Twój system jest teraz gotowy do użycia."

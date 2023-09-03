#!/bin/bash

# Install Docker and Docker Compose
sudo apt update && sudo apt install -y docker.io docker-compose && sudo systemctl enable docker && sudo systemctl start docker

# Create and decode Docker Compose file
echo "dmVyc2lvbjogJzMnCnNlcnZpY2VzOgogIHdpcmVndWFyZDoKICAgIGltYWdlOiBsaW51eHNlcnZlci93aXJlZ3VhcmQKICAgIG5ldHdvcmtzOgogICAgICAtIG15X25ldHdvcmsKICBteXNxbDoKICAgIGltYWdlOiBteXNxbDpsYXRlc3QKICAgIG5ldHdvcmtzOgogICAgICAtIG15X25ldHdvcmsKICBtYWlsOgogICAgaW1hZ2U6IG1haWxzZXJ2ZXIvZG9ja2VyLW1haWxzZXJ2ZXI6bGF0ZXN0CiAgICBuZXR3b3JrczoKICAgICAgLSBteV9uZXR3b3JrCm5ldHdvcmtzOgogIG15X25ldHdvcms6CiAgICBkcml2ZXI6IGJyaWRnZQ==" | base64 -d > docker-compose.yml

# Run Docker Compose
docker-compose up -d

# Setup WordPress sites
for i in {1..8}; do
  domain=$(shuf -zer -n6 {a..z}{A..Z}{0..9})
  docker run --name $domain --network my_network -e WORDPRESS_DB_HOST=mysql -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=root -d wordpress:latest
done

# Create email accounts
docker exec -it mail setup email add hello@mail.wg mypassword & docker exec -it mail setup email add no-reply@mail.wg mypassword

# Install Wiki.js
docker run -d --name wiki --network my_network -e DB_TYPE=mysql -e DB_HOST=mysql -e DB_PORT=3306 -e DB_USER=root -e DB_PASS=root -e DB_NAME=wiki -p 3000:3000 requarks/wiki:2

# Output
echo "Configuration complete. Your Docker containers are now running."

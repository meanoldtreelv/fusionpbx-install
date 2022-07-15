#!/bin/bash

#lets get docker installed
echo "installing Docker and joining to swarm"

#install the docker apt repo
apt-get install -y ca-certificates curl gnupg
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

#install docker packages
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

#join the swarm as a manager
docker swarm join --token SWMTKN-1-5w4ekdzj9gkwf0i302z5rw8iyycxwk224yif3cedx0p0irno68-4d1ds41i6fzvcznhc3un3mbuf 10.3.34.209:2377

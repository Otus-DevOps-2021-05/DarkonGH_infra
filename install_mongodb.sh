#!/bin/bash

if sudo apt-get install -y apt-transport-https ca-certificates
then
  wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
  echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
fi

sudo apt-get update

if sudo apt-get install -y mongodb-org
then
    sudo systemctl start mongod
    sudo systemctl enable mongod
fi

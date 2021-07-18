#!/bin/bash

apt-get -y update

if apt-get install -y apt-transport-https ca-certificates
  then
    wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list
  fi

apt-get update

if apt-get install -y mongodb-org
then
    systemctl start mongod
    systemctl enable mongod
fi

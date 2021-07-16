#!/bin/bash

sudo apt install -y git

mv /tmp/puma.service /etc/systemd/system/puma.service
cd /opt
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
systemctl daemon-reload
systemctl enable puma
systemctl start puma

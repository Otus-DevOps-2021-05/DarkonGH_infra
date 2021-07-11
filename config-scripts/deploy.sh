#!/bin/bash

sudo apt install -y git

echo "The home dir is:" $HOME
if cd ~
then
  if git clone -b monolith https://github.com/express42/reddit.git && [ -d ~/reddit ]
  then
    if cd reddit && bundle install
      then
        if puma -d
        then
          ps aux | grep puma
        fi
      else
        echo "Cannot start servise puma"
    fi
  else
    echo "Cannot connect to repository"
  fi
else
  echo "Cannot open Home dir: $HOME"
fi

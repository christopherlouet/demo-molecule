#!/bin/bash

sudo apt update -qq
sudo apt install apt-transport-https ca-certificates curl software-properties-common -qq

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update -qq
sudo apt install docker-ce

docker ps

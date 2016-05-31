#!/usr/bin/env bash

sudo apt-get update
sudo apt-get upgrade -y

curl -L -s http://git.openstack.org/cgit/openstack/faafo/plain/contrib/install.sh | bash -s -- -i faafo -r worker -e 'http://${controller_ip}' -m 'amqp://guest:guest@%${controller_ip}:5672/

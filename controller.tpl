#!/usr/bin/env bash

curl -L -s http://git.openstack.org/cgit/openstack/faafo/plain/contrib/install.sh | bash -s -- -i messaging -i faafo -r api

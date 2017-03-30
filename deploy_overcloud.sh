#!/bin/bash

cd /home/stack

time openstack overcloud deploy --templates \
   --ntp-server pool.ntp.org \
   --control-scale 1 \
   -e /home/stack/templates/compute_roles.yaml -r /home/stack/templates/roles_data.yaml \
   -e /home/stack/templates/firstboot/environment-firstboot.yaml \
   -e /home/stack/templates/network/network-isolation.yaml \
   -e /home/stack/templates/network/ips-from-pool-all.yaml \
   -e /home/stack/templates/network/environment-network.yaml


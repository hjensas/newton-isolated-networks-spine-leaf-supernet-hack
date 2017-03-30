#!/bin/bash

source /home/stack/stackrc

openstack baremetal node set --property capabilities=profile:control,boot_option:local osp10-ctrl0
openstack baremetal node set --property capabilities=profile:leaf1-compute,boot_option:local osp10-leaf1cmp0
openstack baremetal node set --property capabilities=profile:leaf2-compute,boot_option:local osp10-leaf2cmp0
openstack baremetal node set --property capabilities=profile:leaf1-compute,boot_option:local osp10-leaf3cmp0


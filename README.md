# newton-isolated-networks-spine-leaf-supernet-hack
Deploy Openstack newton with routed isolated networks, using custom roles. No
tripleo-heat-teamplates customization required.

Network environment files in this repo is an example showing how one can trick
Triple-O into deploying overcloud with routed (spine-leaf) networks on the
isolated networks. This is done by utilizing the custom role feature
introduced in Openstack Newton. One custom compute role is created per _leaf_
each with a role specific nic-config template that configures the correct _ip,
netmask and static routes_ on overcloud nodes.

The **provisioning** network used for introspection and dhcp/pxe based provisioning must be a **single L2 broadcast domain**.

## Limitations:
* All ip subnets used as leafs must be a supernet, a portion of a larger network.
  * Neutron network on undercloud is configured with a single subnet, and has no knowledge that the subnet is actually split up into multiple supernets.
* Predictable IP's are requiered to ensure each node is assigned an ip address in the correct supernet. (network/ips-from-pool-all.yaml)
* Scalability is limited to the size of neutron networks, the number of adjecent supernets available.
* The fabric network must be configure to handle the routing.
* The fabric network must be configured to manage security.
  * ACL/Firewall is required in the routed fabric to ensure private networks are isolated.

## Architecture

### Network

Internal API network: 172.20.4.0/24
* Supernets:
  * 172.20.4.0/26   (Leaf0)
  * 172.20.4.64/26  (Leaf1)
  * 172.20.4.128/26 (Leaf2)
  * 172.20.4.192/26 (Leaf3)

Tenant network: 172.20.5.0/25
* Supernets:
  * 172.20.5.0/26   (Leaf0)
  * 172.20.5.64/26  (Leaf1)
  * 172.20.5.128/26 (Leaf2)
  * 172.20.5.192/26 (Leaf3)

Storage network: 172.20.6.0/24
* Supernets:
  * 172.20.6.0/26   (Leaf0)
  * 172.20.6.64/26  (Leaf1)
  * 172.20.6.128/26 (Leaf2)
  * 172.20.6.192/26 (Leaf3)

Management network: 172.20.3.0/24
* Supernets:
  * 172.20.3.0/26   (Leaf0)
  * 172.20.3.64/26  (Leaf1)
  * 172.20.3.128/26 (Leaf2)
  * 172.20.3.192/26 (Leaf3)

Extenal network: 172.20.1.0/26
 * No supernets, external network is only on controller nodes.

Storage management network: 172.20.7.0/26
 * No supernets, stoage management is only on controller nodes.

### Deployed nodes

Node             |  Leaf   |  Function (Role)
---------------- | ------- | -----------------------
osp10-ctrl0      |  leaf0  |  Controller node
osp10-leaf1cmp0  |  leaf1  |  Compute node
osp10-leaf2cmp0  |  leaf2  |  Compute node
osp10-leaf3cmp0  |  leaf3  |  Compute node

## Template files

### templates/compute_roles.yaml

Contains parameters for node cound for compute roles as well as scheduler
hints for each compute role.

### templates/roles_data.yaml

Roles data file with the added per _leaf_ compute roles.

### templates/network/environment-network.yaml

Contains resource registry to map nic-config templates to each role.

For each network, _internalapi, storage, teant, management etc._,
Leaf specific parameters are added to control CIDR, VlanID and router
 address.

### templates/network/ips-from-pool-all.yaml

This contains the _predictable_ ip mappings for each node, as well as the
cluster virtual ips (vip's). The use of _predictable_ ip mapping is required
to ensure overcloud nodes are assigned ip addresses within the correct _leaf_
supernet.

### templates/network/network-isolation.yaml

This is the default network-isolation template that come with THT, only change
is that management network is enabled.

### templates/network/nic-configs/

Directory contains NIC configs for each role.
   
* controller.yaml
* leaf1-compute.yaml
* leaf2-compute.yaml
* leaf3-compute.yaml

Parameters for per network and leaf _router, VlanID and NetCidr_ are added.
From these parameters, the _addresses_ and _static routes_ are templated.


`str_split:` and `list_join:` is used to get the IP address from
InternalApiIpSubnet parameter, as well as the network mask bits from
the leaf specific cidr _InternalApiNetCidrLeaf1_ to assign correct
ip interface address and netmask.

Per leaf cidr parameter _InternalApiNetCidrLeafX_ and leaf specific router
parameter _InternalApiIpSubnetRouterLeaf0_ used to set up the required static
routes.

Example:
```
-
  type: vlan
  device: nic2
  vlan_id: {get_param: InternalApiNetworkVlanIDLeaf0}
  addresses:
    -
      ip_netmask:
        list_join:
          - '/'
          - - {str_split: ['/', {get_param: InternalApiIpSubnet}, 0]}
            - {str_split: ['/', {get_param: InternalApiNetCidrLeaf1}, 1]}
  routes:
    -
      default: false
      ip_netmask: {get_param: InternalApiNetCidrLeaf1}
      next_hop: {get_param: InternalApiIpSubnetRouterLeaf0}
    -
      default: false
      ip_netmask: {get_param: InternalApiNetCidrLeaf2}
      next_hop: {get_param: InternalApiIpSubnetRouterLeaf0}
    -
      default: false
      ip_netmask: {get_param: InternalApiNetCidrLeaf3}
      next_hop: {get_param: InternalApiIpSubnetRouterLeaf0}
```


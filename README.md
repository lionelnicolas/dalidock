# A dockerized DNS server and load balancer with automatic discovery

`dalidock` is a container providing the following services:

 * DNS server, with `dnsmasq`
 * load balancer, with `haproxy`
 * service discovery, with the `dalidock` python script

Services can be discovered from:

 * docker containers
 * libvirt virtual machines

## Usage

### Run the container

`dalidock` can be configured using environment variables:

| Variable             | Default                         | Description                                               |
|----------------------|---------------------------------|-----------------------------------------------------------|
| `DNS_WILDCARD `      | `false`                         | Enable DNS wildcard records by default                    |
| `DNS_DOMAIN`         | `local`                         | Domain to append to DNS records to register               |
| `LB_DOMAIN`          | `local`                         | Domain to append to reverse-proxy DNS records to register |
| `USE_AD_BLOCKER`     | `false`                         | Override hosts using https://github.com/StevenBlack/hosts |
| `DOCKER_SOCKET`      | `unix://var/run/docker.sock`    | Docker daemon socket                                      |
| `LIBVIRT_SOCKET`     | `/var/run/libvirt/libvirt-sock` | Libvirt daemon socket                                     |
| `LIBVIRT_IP_TIMEOUT` | `30.0`                          | Timeout for dalidock to detect a VM's IP address          |

```sh
docker run \
    --detach \
    --name dalidock \
    --hostname dalidock \
    --restart=unless-stopped \
    --net bridge \
    --log-opt max-size=50m \
    --log-opt max-file=3 \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --cap-add NET_ADMIN \
    --publish 172.17.0.1:53:53/udp \
    --publish 80:80 \
    --env DNS_DOMAIN=my.local.env \
    --env LB_DOMAIN=my.local.env \
    lionelnicolas/dalidock
```

### Make your host uses dalidock as a DNS server

If your system uses NetworkManager, `/etc/resolv.conf` is probably a symlink pointing to a
file generated by NetworkManager. So you'll first need to remove that symlink and recreate
`/etc/resolv.conf`. Then replace its content with:

```
search my.local.env
domain my.local.env
nameserver 172.17.0.1
```

### Uses NetworkManager's data for upstream DNS servers

If your system uses NetworkManager, `/run/NetworkManager/resolv.conf` contains the DNS server
addresses got from network configuration (DHCP, manual ...)

`dalidock` can handle wifi/ethernet/VPN connection switches by watching this file, and tell
dnsmasq to reload and use "new" upstream servers.

If you want to use that feature, you'll just need to map this directory when starting the
`dalidock` container:

```shell=/bin/sh
    --volume /run/NetworkManager:/run/NetworkManager:ro
```


## Register containers

### Default values

when starting a new container, both `name` and `hostname` will be registered in the DNS. So
if you start a container using:

```shell=/bin/sh
docker run \
    -it \
    --name qwerty \
    --hostname asdfgh \
    ubuntu
```

Then, the following DNS records will be available:

```
qwerty.                   0   IN   A   172.17.0.7
asdfgh.                   0   IN   A   172.17.0.7
qwerty.my.local.env.      0   IN   A   172.17.0.7
asdfgh.my.local.env.      0   IN   A   172.17.0.7
7.0.17.172.in-addr.arpa.  0   IN   PTR asdfgh.my.local.env.
```

### Override DNS domain

```shell=/bin/sh
docker run \
    -it \
    --name qwerty \
    --hostname asdfgh \
    --label dns.domain=other.fqdn \
    ubuntu
```

Then, the following DNS records will be available:

```
qwerty.                   0   IN   A   172.17.0.7
asdfgh.                   0   IN   A   172.17.0.7
qwerty.other.fqdn.        0   IN   A   172.17.0.7
asdfgh.other.fqdn.        0   IN   A   172.17.0.7
7.0.17.172.in-addr.arpa.  0   IN   PTR asdfgh.other.fqdn.
```

### Add DNS aliases

```shell=/bin/sh
docker run \
    -it \
    --name qwerty \
    --hostname asdfgh \
    --label dns.domain=other.fqdn \
    --label dns.aliases=alias1,alias2,otheralias \
    ubuntu
```

Then, the following DNS records will be available:

```
qwerty.                   0   IN   A   172.17.0.7
asdfgh.                   0   IN   A   172.17.0.7
alias1.                   0   IN   A   172.17.0.7
alias2.                   0   IN   A   172.17.0.7
otheralias.               0   IN   A   172.17.0.7
qwerty.other.fqdn.        0   IN   A   172.17.0.7
asdfgh.other.fqdn.        0   IN   A   172.17.0.7
alias1.other.fqdn.        0   IN   A   172.17.0.7
alias2.other.fqdn.        0   IN   A   172.17.0.7
otheralias.other.fqdn.    0   IN   A   172.17.0.7
7.0.17.172.in-addr.arpa.  0   IN   PTR asdfgh.other.fqdn.
```

### Enable wildcard DNS

```shell=/bin/sh
docker run \
    -it \
    --name qwerty \
    --hostname asdfgh \
    --label dns.wildcard=true \
    ubuntu
```

Then, the following DNS records will be available:

```
qwerty.                   0   IN   A   172.17.0.7
asdfgh.                   0   IN   A   172.17.0.7
*.qwerty.                 0   IN   A   172.17.0.7
*.asdfgh.                 0   IN   A   172.17.0.7
qwerty.my.local.env.      0   IN   A   172.17.0.7
asdfgh.my.local.env.      0   IN   A   172.17.0.7
*.qwerty.my.local.env.    0   IN   A   172.17.0.7
*.asdfgh.my.local.env.    0   IN   A   172.17.0.7
7.0.17.172.in-addr.arpa.  0   IN   PTR asdfgh.my.local.env.
```

### Add a reverse-proxy entry in haproxy

```shell=/bin/sh
docker run \
    -it \
    --name tomcat-server \
    --hostname tomcat-server \
    --label lb.http=tomcat:8080 \
    tomcat:8.0
```

This will create an haproxy frontend matching `http://tomcat.*`, and redirect traffic to
port 8080 of the `tomcat-server` container.

Then, the following DNS records will be available:

```
tomcat-server.              0   IN   A   172.17.0.7
tomcat-server.my.local.env. 0   IN   A   172.17.0.7
tomcat.                     0   IN   A   172.17.0.2
tomcat.my.local.env.        0   IN   A   172.17.0.2
7.0.17.172.in-addr.arpa.    0   IN   PTR tomcat-server.my.local.env.
```

Please note that `lb.http` label can take comma-separated list of `HOST:PORT`.

### Add a reverse-proxy entry in haproxy (and override DNS domain)

```shell=/bin/sh
docker run \
    -it \
    --name tomcat-server \
    --hostname tomcat-server \
    --label lb.http=tomcat:8080 \
    --label lb.domain=frontend.srv \
    tomcat:8.0
```

This will create an haproxy frontend matching `http://tomcat.*`, and redirect traffic to
port 8080 of the `tomcat-server` container.

Then, the following DNS records will be available:

```
tomcat-server.              0   IN   A   172.17.0.7
tomcat-server.my.local.env. 0   IN   A   172.17.0.7
tomcat.                     0   IN   A   172.17.0.2
tomcat.frontend.srv.        0   IN   A   172.17.0.2
7.0.17.172.in-addr.arpa.    0   IN   PTR tomcat-server.my.local.env.
```

Please note that `lb.http` label can take comma-separated list of `HOST:PORT`.

## Register libvirt-based virtual machines

### Prerequisites

You'll need to ensure that `dalidock` has access to the libvirt daemon socket, by adding
that volume mapping when starting the container:

```
--volume /var/run/libvirt:/var/run/libvirt:ro
```

### IP address detection

`dalidock` will try to detect the VM's IP address when the `Started` event is detected. If no IP
address is found after `LIBVIRT_IP_TIMEOUT`, then the VM will be ignored.

Please note that this detection will only work if either:

 1. VM primary network interface is configured as DHCP, and is using libvirt-managed DHCP
    server (`dnsmasq`)
 1. [Qemu guest agent](https://wiki.libvirt.org/page/Qemu_guest_agent) is enabled in libvirt,
    and running in the VM

As soon as the IP address is detected, the following DNS record will be available:

```
${VM_NAME}.${DNS_DOMAIN}.   0   IN   A   ${VM_IP_ADDRESS}
```

### Labels

Libvirt doesn't have labels, so `dalidock` use [metadata](https://libvirt.org/formatdomain.html#elementsMetadata)
instead, which needs to be set in the virtual machine XML description. This can be achieved
by editing the XML with `virsh edit my-vm-to-discover`, or by using the `virsh metadata` command:

With libvirt, `dalidock` works using the same labels as for [containers](#register-containers).

For example, to enable wildcard DNS on a virtual machine, you can use:

```sh
virsh metadata my-vm-to-discover \
	--config \
	--uri http://github.com/lionelnicolas/dalidock \
	--key dalidock \
	--set '<labels dns.wildcard="true"/>'
```

Or to add reverse-proxy entries:

```sh
virsh metadata my-vm-to-discover \
	--config \
	--uri http://github.com/lionelnicolas/dalidock \
	--key dalidock \
	--set '<labels lb.http="tomcat:8080" lb.domain="frontend.srv"/>'
```

## Build

In order to build this container image instead of using the one on the Docker Hub,
you can use the following command from the root directory of this repository:

```bash
docker build -t lionelnicolas/dalidock .
```

## License

This is licensed under the Apache License, Version 2.0. Please see [LICENSE](https://github.com/lionelnicolas/dalidock/blob/master/LICENSE)
for the full license text.

Copyright 2016-2020 Lionel Nicolas

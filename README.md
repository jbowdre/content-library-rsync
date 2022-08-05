# library-syncer

This project aims to ease some of the pains encountered when attempting to sync VM templates in a [VMware vSphere Content Library](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.vm_admin.doc/GUID-254B2CE8-20A8-43F0-90E8-3F6776C2C896.html) to a large number of geographically-remote sites under less-than-ideal networking conditions. 

## Overview
The solution leverages lightweight Docker containers in server and client roles. The servers would be deployed at the primary datacenter(s), and the clients at the remote sites. The servers make a specified library folder available for the clients to periodically synchronize using `rsync` over SSH, which allows for delta syncs so that bandwidth isn't wasted transferring large VMDK files when only small portions have changed. 

Once the sync has completed, each client runs a [Python script](client/build/update_library_manifests.py) to generate/update a Content Library JSON manifest which is then published over HTTP/HTTPS (courtesy of [Caddy](https://caddyserver.com/)). Traditional Content Libraries at the local site can connect to this as a [subscribed library](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.vm_admin.doc/GUID-9DE2BD8F-E499-4F1E-956B-67212DE593C6.html) to make the synced items available within vSphere.

The rough architecture looks something like this:
```
                        |
     PRIMARY SITE       |      REMOTE SITES      +----------------------------+
                        |                        |          vSphere           |
                        |    +----------------+  |   +--------------------+   |
                        |    |                |  |   |                    |   |
                        |    | library-syncer |  |   | subscribed content |   |
                     +--+--->|                +--+-->|                    |   |
                     |  |    |    client      |  |   |      library       |   |
                     |  |    |                |  |   |                    |   |
                     |  |    +----------------+  |   +--------------------+   |
                     |  |                        |                            |
+-----------------+  |  |    +----------------+  |   +--------------------+   |
|                 |  |  |    |                |  |   |                    |   |
|  library-syncer |  |  |    | library-syncer |  |   | subscribed content |   |
|                 +--+--+--->|                +--+-->|                    |   |
|     server      |  |  |    |    client      |  |   |      library       |   |
|                 |  |  |    |                |  |   |                    |   |
+-----------------+  |  |    +----------------+  |   +--------------------+   |
                     |  |                        |                            |
                     |  |    +----------------+  |   +--------------------+   |
                     |  |    |                |  |   |                    |   |
                     |  |    | library-syncer |  |   | subscribed content |   |
                     +--+--->|                +--+-->|                    |   |
                        |    |    client      |  |   |      library       |   |
                        |    |                |  |   |                    |   |
                        |    +----------------+  |   +--------------------+   |
                        |                        +----------------------------+
```

## Prerequisites
### Rsync user SSH keypair
The server image includes a `syncer` user account which the clients will use to authenticate over SSH. This account is locked down and restricted with `rrsync` to only be able to run `rsync` commands. All that you need to do is generate a keypair for the account to use:

```shell
ssh-keygen  -t rsa -b 4096 -N "" -f id_syncer
```

Place the generated `id_syncer` *private* key in `./data/ssh/` on the *client* Docker hosts, and the `id_syncer.pub` *public* key in `./data/ssh/` on the *server* Docker host.

### TLS certificate pair (optional)
By default, the client will publish its library over HTTP. If you set the `TLS_NAME` environment variable to the server's publicly-accessible FQDN, the Caddy web server will [automatically retrieve and apply a certificate issued by Let's Encrypt](https://caddyserver.com/docs/automatic-https). For deployments on internal networks which need to use a certificate issued by an internal CA, you can set `TLS_CUSTOM_CERT=true` and place the PEM-formatted certificate *and* private key in the client's `./data/certs/` directory, named `cert.pem` and `key.pem` respectively.

You can generate the cert signing request and key in one shot like this:
```shell
openssl req -new \
-newkey rsa:4096 -nodes -keyout library.example.com.key \
-out library.example.com.csr \
-subj "/C=US/ST=Somestate/L=Somecity/O=Example.com/OU=LAB/CN=library.example.com"
```

## Usage
### Server
Directory structure:
```
.
├── data
│   ├── library
│   └── ssh
│       └── id_syncer.pub
└── docker-compose.yaml
```

`docker-compose.yaml`:
```yaml
version: '3'
services:
  library-syncer-server:
    container_name: library-syncer-server
    restart: unless-stopped
    image: ghcr.io/jbowdre/library-syncer-server:latest
    environment:
      - TZ=UTC
    ports:
      - "2222:22"
    volumes:
      - './data/ssh:/home/syncer/.ssh'
      - './data/library:/syncer/library'
```

### Client
Directory structure:
```
.
├── data
│   ├── certs
│   │   ├── cert.pem
│   │   └── key.pem
│   ├── library
│   └── ssh
│       └── id_syncer
└── docker-compose.yaml
```

`docker-compose.yaml`:
```yaml
version: '3'
services:
  library-syncer-client:
    container_name: library-syncer-client
    restart: unless-stopped
    image: ghcr.io/jbowdre/library-syncer-client:latest
    environment:
      - TZ=UTC
      - SYNC_PEER=deb01.lab.bowdre.net
      - SYNC_PORT=2222
      - SYNC_SCHEDULE=0 21 * * 5
      - SYNC_DELAY=true
      - TLS_NAME=library.lab.bowdre.net
      - TLS_CUSTOM_CERT=true
    ports:
      - "80:80/tcp"
      - "443:443/tcp"
    volumes:
      - './data/ssh:/syncer/.ssh'
      - './data/library:/syncer/library'
      - './data/certs:/etc/caddycerts'
```
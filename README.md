# octoBIND
A dead-simple DNS server using bind9, configure for using with [octoDNS](https://github.com/octodns/octodns).

## Build

Run the following command to build the Docker Image:

```sh
make
// or 
make build
```

## Usage

Before you can use the Docker Compose, please build you own Docker Image following the above example.

### Using Docker Compose

```yml
# docker-compose.yml
version: "3.10"

services:
  bind:
    image: localhost/bind9:latest
    ports:
      - 53:53/udp
      - 53:53/tcp
      - 127.0.0.1:953:953/tcp
    environment:
      DEBUG: "true"
      NS_SERVER_ROLE: primary
      NS_PRIMARIES_ADDR: 10.10.100.6
      NS_SECONDARIES_ADDR: 10.10.100.6, 10.10.100.7
      NS_FORWARDERS_ADDR: 8.8.8.8, 8.8.4.4
      ZONES_AVAILABLE: sorakh.local,terra.sorakh.one
      OCTODNS_KEY_FILE: /var/run/secrets/octodns.key
    volumes:
      - /etc/bind
      - /var/lib/bind
      - /var/cache/bind
      - /var/log/bind
    secrets:
      - octodns.key

secrets:
  octodns.key:
    file: octodns.key
```

Run `docker compose up -d` to start the service.

## Configurations

You can configure the server using Environment Variables. Here are a few thing you can do.

#### Example

```sh
NS_SERVER_DOMAIN="${NS_SERVER_DOMAIN:-nameserver.corpnet}"
NS_SERVER_ROLE="${NS_SERVER_ROLE:-primary}"

# Primary nameserver addresses
NS_PRIMARY_IPS=<Primary nameserver IP addresses>

# Secondary nameserver addresses
NS_SECONDARY_IPS=<Secondary nameserver IP addresses>

# (Optional) Other primary nameserver to get notify by this server
NS_ALSO_NOTIFY_ADDR=<Other Primary nameserver IP addresses>

# (Optional) Forwarder addresses
# Google Public DNS
NS_FORWARDERS_ADDR=8.8.8.8,8.8.4.4

# Cloudflare DNS
# NS_FORWARDERS_ADDR=1.1.1.1,1.0.0.1

# Cloudflare DNS \w Malware Blocking
# NS_FORWARDERS_ADDR=1.1.1.2,1.0.0.2

# Cloudflare DNS \w Malware and Adult Content Blocking
# NS_FORWARDERS_ADDR=1.1.1.3,1.0.0.3

# Available zones
ZONES_AVAILABLE=example.com, example.local

# OctoDNS Key
OCTODNS_KEY_NAME=octodns-key
OCTODNS_KEY_FILE=/etc/bind/octodns.key
```

### Name Server configuration (Required)

- **NS_SERVER_DOMAIN**: A FQDN or local domain for the Nameserver, e.g. `nameserver.localhost` (default: `nameserver.localhost`)
- **NS_SERVER_ROLE**: The Nameserver role, `primary` or `secondary` (default: `primary`)
- **NS_PRIMARY_IPS**: A comma-separated string for primary nameservers.
- **NS_SECONDARY_IPS**: A comma-separated string for secondary nameservers.
- **NS_FORWARDERS_ADDR**: ***(Optional)*** A comma-separated string for forwarding as recursive nameserver.

### Add zone configurations (Required)

- **ZONES_AVAILABLE**: A comma-separated string for available zones.
e.g. `ZONES_AVAILABLE=exxample.com.local,exxample.net.local`

### Advanced configurations

- **NS_ALSO_NOTIFY_ADDR**: ***(Optional)*** A comma-separated string for other primary nameservers to notify.
- **OCTODNS_KEY_NAME**: ***(Optional)*** The default key name for OctoDNS.
- **OCTODNS_KEY_FILE**: ***(Optional)*** The default key file for OctoDNS.
---

## Zone Management with OctoDNS

In the vein of infrastructure as code OctoDNS provides a set of tools & patterns that make it easy to manage your DNS records across multiple providers. The resulting config can live in a repository and be deployed just like the rest of your code, maintaining a clear history and using your existing review & workflow.

Check out https://github.com/octodns/octodns for documentations.

## License
Licensed under [MIT License](LICENSE).

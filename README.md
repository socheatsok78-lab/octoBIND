# octoBIND
A dead-simple DNS server using bind9.

## Usage

### Using Docker Compose

```yml
version: "3.10"

services:
  bind:
    image: localhost/bind9:latest
    ports:
      - 53:53/udp
      - 53:53/tcp
      - 127.0.0.1:953:953/tcp
    environment:
      DEBUG: 1
      NS_FORWARDERS: 1.1.1.1
      NS_SERVER_ROLE: primary
      NS_SERVER_COUNT: 2
      NS_SERVER_1_ADDR: 10.10.200.6
      NS_SERVER_2_ADDR: 10.10.200.7
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

## Configurations

You can configure the server using Environment Variables. Here are a few thing you can do.

#### Example

```env
NS_SERVER_DOMAIN=nameserver.local
NS_SERVER_ROLE=primary
NS_SERVER_COUNT=1
NS_SERVER_1_ADDR=192.168.131.151
ZONES_AVAILABLE=exxample.com.local,exxample.net.local
```

### Name Server configuration (Required)

- **NS_SERVER_DOMAIN**: A FQDN or local domain for the Nameserver, e.g. `nameserver.localhost` (default: `nameserver.localhost`)
- **NS_SERVER_ROLE**: The Nameserver role, `primary` or `secondary` (default: `primary`)
- **NS_SERVER_COUNT**: The number of available Nameservers (default: 1)
- **NS_SERVER_${i}_ADDR**: The IP Address of the current/next Nameserver based on the `NS_SERVER_COUNT` value.  
e.g. If the `NS_SERVER_COUNT=2`, the server will expect you to set `NS_SERVER_1_ADDR` and `NS_SERVER_2_ADDR` value. ***(Replace the ${i} with an index starting from `1`)***

### Add zone configurations (Required)

- **ZONES_AVAILABLE**: A comma-separated string for available zones.  
e.g. `ZONES_AVAILABLE=exxample.com.local,exxample.net.local`

---

## What this does?

### Stage 1
1. Backup `/etc/bind/named.conf.local` to `/etc/bind/named.conf.local.origin`
1. Generate a new copy of `named.conf.local` from `named.conf.local.origin`
1. If `RNDC_KEY_FILE` env is set
    - Backup `/etc/bind/rndc.key` to `/etc/bind/rndc.key.origin`
    - Replace `rndc.key` with the `RNDC_KEY_FILE` file content.
1. Generate a new key using `rndc-confgen` for `OCTODNS_KEY_NAME` and `OCTODNS_KEY_FILE`
1. Read key from `OCTODNS_KEY_FILE` and append it to `named.conf.local`

### Stage 2
#### Primary Server
1. Append zone config for top-level Nameserver to `named.conf.local`
1. Generate zone file for the top-level Nameserver with `NS_SERVER_DOMAIN` and `NS_SERVER_ROLE`
    - `NS_SERVER_DOMAIN`: A FQDN or local domain for the Nameserver, e.g. `nameserver.localhost` (default: `nameserver.localhost`)
    - `NS_SERVER_ROLE`: The Nameserver role, `primary` or `secondary` (default: `primary`)
1. Parse and populate available Nameservers via `NS_SERVER_COUNT` and add to the top-level Nameserver zone file.
    - `NS_SERVER_COUNT`: The number of available Nameservers (default: 1)
    - `NS_SERVER_${i}_ADDR`: The IP Address of the current/next Nameserver based on the `NS_SERVER_COUNT` value.  
    e.g. If the `NS_SERVER_COUNT=2`, the server will expect you to set `NS_SERVER_1_ADDR` and `NS_SERVER_2_ADDR` value. ***(Replace the ${i} with an index starting from `1`)***

#### Secondary Server
1. Append zone config for top-level Nameserver to `named.conf.local`

### Stage 3
####  Primary Server
1. Parse `ZONES_AVAILABLE` value and generate zone file for each item in the list. ***(The `ZONES_AVAILABLE` can be set a comma-separated value)***.
1. Append each zone config to `named.conf.local`

#### Secondary Server
1. Parse `ZONES_AVAILABLE` value and append each zone config to `named.conf.local`. ***(The `ZONES_AVAILABLE` can be set a comma-separated value)***.

### Stage 4

Start `named` service with `/etc/bind/named.conf` config.

## License
Licensed under [MIT License](LICENSE).

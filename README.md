# octoBIND
A dead-simple DNS server using bind9.

## Configurations

You can configure the server using Environment Variables. Here are a few thing you can do.

#### Example

```env
NS_SERVER_DOMAIN=nameserver.local
NS_SERVER_ROLE=primary
NS_SERVER_COUNT=1
NS_SERVER_1_ADDR=192.168.131.151
AVAILABLE_ZONES=exxample.com.local,exxample.net.local
```

### Name Server configuration (Required)

- **NS_SERVER_DOMAIN**: A FQDN or local domain for the Nameserver, e.g. `nameserver.localhost` (default: `nameserver.localhost`)
- **NS_SERVER_ROLE**: The Nameserver role, `primary` or `secondary` (default: `primary`)
- **NS_SERVER_COUNT**: The number of available Nameservers (default: 1)
- **NS_SERVER_${i}_ADDR**: The IP Address of the current/next Nameserver based on the `NS_SERVER_COUNT` value.  
e.g. If the `NS_SERVER_COUNT=2`, the server will expect you to set `NS_SERVER_1_ADDR` and `NS_SERVER_2_ADDR` value. ***(Replace the ${i} with an index starting from `1`)***

### Add zone configurations (Required)

- **AVAILABLE_ZONES**: A comma-separated string for available zones.  
e.g. `AVAILABLE_ZONES=exxample.com.local,exxample.net.local`

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
1. Parse `AVAILABLE_ZONES` value and generate zone file for each item in the list. ***(The `AVAILABLE_ZONES` can be set a comma-separated value)***.
1. Append each zone config to `named.conf.local`

#### Secondary Server
1. Parse `AVAILABLE_ZONES` value and append each zone config to `named.conf.local`. ***(The `AVAILABLE_ZONES` can be set a comma-separated value)***.

### Stage 4

Start `named` service with `/etc/bind/named.conf` config.

## License
Licensed under [MIT License](LICENSE).

ARG BIND_VERSION=9.18
FROM internetsystemsconsortium/bind9:${BIND_VERSION}

ARG GOMPLATE_VERSION=v3.11.3
ADD https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERSION}/gomplate_linux-amd64 /usr/bin/gomplate
RUN chmod +x /usr/bin/gomplate

# Overlay rootfs to /
ADD rootfs /

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["/usr/sbin/named", "-g", "-c", "/etc/bind/named.conf", "-u", "bind"]

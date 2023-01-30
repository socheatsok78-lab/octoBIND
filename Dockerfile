ARG BIND_VERSION=9.18
FROM internetsystemsconsortium/bind9:${BIND_VERSION}

# Overlay rootfs to /
ADD rootfs /

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["/usr/sbin/named", "-g", "-c", "/etc/bind/named.conf", "-u", "bind"]

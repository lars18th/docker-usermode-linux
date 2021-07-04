FROM debian:testing-slim AS linux

COPY uml.config /uml.config

ENV LINUX_VERSION linux-5.10.47
ENV LINUX_DOWNLOAD_URL https://cdn.kernel.org/pub/linux/kernel/v5.x/${LINUX_VERSION}.tar.xz

RUN set -x \
  && apt-get update \
  && apt-get -y install build-essential flex bison xz-utils wget ca-certificates bc \
  && wget -O - ${LINUX_DOWNLOAD_URL} | tar -xJ \
  && cd ${LINUX_VERSION} \
  && wget -O - 'https://github.com/zen-kernel/zen-kernel/commit/19c6683e94816fbaef422c446a8ff3d54c973cf3.diff' | patch -p1 \
  && cp /uml.config .config \
  && make ARCH=um olddefconfig \
  && make ARCH=um -j $(($(nproc)+1)) \
  && mv ./linux / \
  && cd .. \
  && rm -rf ${LINUX_VERSION} \
  && chmod +x /linux \
  && rm -rf /var/lib/apt/lists/*


FROM debian:testing-slim

# Add tini
ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini-static /

# Add slirp and deps
RUN chmod +x /tini-static \
  && apt-get update \
  && apt-get install --no-install-recommends -y slirp wget xz-utils ca-certificates \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir /rootfs \
  && wget -O - 'https://alpha.de.repo.voidlinux.org/live/20210316/void-x86_64-musl-ROOTFS-20210316.tar.xz' | tar xJ -C /rootfs

RUN set -x \
  && printf '%s\n' 'ignorepkg=vhba-module-dkms' > /rootfs/etc/xbps.d/vhba.conf \
  && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /rootfs/etc/ssh/sshd_config \
  && sed -i 's#/bin/sh#/bin/bash#' /rootfs/etc/passwd \
  && printf '\n%s\n%s\n%s\n' \
    'ip link set eth0 up' \
    'ip address add 10.0.2.15/24 dev eth0' \
    'ip route add default via 10.0.2.2' >> /rootfs/etc/rc.local \
  && cp /etc/resolv.conf /rootfs/etc/resolv.conf \
  && chroot /rootfs xbps-install -Sy haveged targetcli-fb cdemu-client dbus-x11 \
  && echo "nameserver 10.0.2.3" > /rootfs/etc/resolv.conf \
  && bash -c 'touch /rootfs/etc/sv/agetty-tty{1,2,3,4,5,6}/down' \
  && ln -s /etc/sv/sshd /rootfs/etc/runit/runsvdir/default/ \
  && ln -s /etc/sv/haveged /rootfs/etc/runit/runsvdir/default/


# Copy files
COPY --from=linux /linux /linux
COPY slirp.sh /slirp.sh
COPY runlinux.sh /runlinux.sh

EXPOSE 2222

ENTRYPOINT [ "/tini-static", "/runlinux.sh", "--" ]

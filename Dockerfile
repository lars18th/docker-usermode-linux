FROM debian:testing-slim AS linux

COPY uml.config /uml.config

ENV LINUX_VERSION linux-6.3.8
ENV LINUX_DOWNLOAD_URL https://cdn.kernel.org/pub/linux/kernel/v6.x/${LINUX_VERSION}.tar.xz

RUN set -x \
  && apt-get update \
  && apt-get -y install build-essential flex bison xz-utils wget ca-certificates bc

# Install LLVM v.15 packages
RUN set -x \
  && apt-get -y install lsb-release wget software-properties-common gnupg2 \
  && wget https://apt.llvm.org/llvm.sh \
  && chmod +x llvm.sh \
  && ./llvm.sh 15 all

RUN set -x \
  && wget -O - ${LINUX_DOWNLOAD_URL} | tar -xJ \
  && cd ${LINUX_VERSION} \
  && cp /uml.config .config \
  && make LLVM=-15 ARCH=um olddefconfig \
  && make LLVM=-15 ARCH=um -j $(($(nproc)+1)) \
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
  && wget -O - 'https://alpha.de.repo.voidlinux.org/live/20221001/void-x86_64-musl-ROOTFS-20221001.tar.xz' | tar xJ -C /rootfs

RUN set -x \
  && printf '%s\n' 'ignorepkg=vhba-module-dkms' > /rootfs/etc/xbps.d/vhba.conf \
  && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /rootfs/etc/ssh/sshd_config \
  && sed -i 's#/bin/sh#/bin/bash#' /rootfs/etc/passwd \
  && printf '\n%s\n%s\n%s\n' \
    'ip link set eth0 up' \
    'ip address add 10.0.2.15/24 dev eth0' \
    'ip route add default via 10.0.2.2' >> /rootfs/etc/rc.local \
  && cp /etc/resolv.conf /rootfs/etc/resolv.conf \
  && chroot /rootfs xbps-install -Syu xbps \
  && chroot /rootfs xbps-install -Sy haveged targetcli-fb cdemu-client dbus dbus-x11 \
  && echo "nameserver 10.0.2.3" > /rootfs/etc/resolv.conf \
  && bash -c 'touch /rootfs/etc/sv/agetty-tty{1,2,3,4,5,6}/down' \
  && ln -s /etc/sv/sshd /rootfs/etc/runit/runsvdir/default/ \
  && ln -s /etc/sv/dbus /rootfs/etc/runit/runsvdir/default/ \
  && ln -s /etc/sv/haveged /rootfs/etc/runit/runsvdir/default/


# Copy files
COPY --from=linux /linux /linux
COPY slirp.sh /slirp.sh
COPY runlinux.sh /runlinux.sh

EXPOSE 22

ENV PORTS 22

ENTRYPOINT [ "/tini-static", "/runlinux.sh", "--" ]

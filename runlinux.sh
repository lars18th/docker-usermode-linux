#!/bin/sh

MEM=${MEM:-256M}

export TMP=/rootfs
exec /linux root=/dev/root rootflags=/rootfs rootfstype=hostfs rw mem="$MEM" verbose eth0=slirp,,/slirp.sh init=/bin/init "$@"

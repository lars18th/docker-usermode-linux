#!/bin/sh

export TMP=/rootfs
exec /linux root=/dev/root rootflags=/rootfs rootfstype=hostfs rw mem=256M verbose eth0=slirp,,/slirp.sh init=/bin/init "$@"

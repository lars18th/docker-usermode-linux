#!/bin/bash

args=( "$@" )

for port in ${PORTS[@]} ; do
	args+=("redir $port $port")
done

exec slirp-fullbolt "${args[@]}"

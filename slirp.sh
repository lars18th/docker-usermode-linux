#!/bin/sh

exec slirp-fullbolt "redir 2222 22" "$@"

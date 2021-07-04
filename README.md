# docker-usermode-linux

A proof of concept [user mode linux](https://en.wikipedia.org/wiki/User-mode_Linux)
Docker image. This builds a simply configured kernel and sets up an [Void Linux](https://voidlinux.org/)
userland for it. It has fully working networking via slirp.

This runs an entire Linux kernel as a userspace process inside a docker container.
Anything you can do as root in a linux kernel, you can do inside this user mode
Linux process. The root inside this user mode Linux kernel has significanly more
power than root outside of the kernel, but it cannot affect the host kernel.

U

To build:

```shell
$ docker build -t JuniorJPDJ/docker-usermode-linux .
```

To run:

```shell
$ docker run -p 2222:2222 --rm JuniorJPDJ/docker-usermode-linux
```

You can then ssh to it:

```shell
$ ssh root@127.0.0.1 -p 2222
```
Default root password is `voidlinux`.

UML uses `/rootfs` directory as root filesystem, so anything mounted to `/rootfs/*` will be visible inside UML.

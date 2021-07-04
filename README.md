# docker-usermode-linux

A proof of concept [user mode linux](https://en.wikipedia.org/wiki/User-mode_Linux)
Docker image. This builds a simply configured kernel and sets up an [Void Linux](https://voidlinux.org/)
userland for it. It has fully working networking via slirp.

This runs an entire Linux kernel as a userspace process inside a docker container.
Anything you can do as root in a linux kernel, you can do inside this user mode
Linux process. The root inside this user mode Linux kernel has significanly more
power than root outside of the kernel, but it cannot affect the host kernel.


To build:

```shell
$ docker build -t juniorjpdj/docker-usermode-linux .
```

To run:

```shell
$ docker run -p 2222:22 --rm juniorjpdj/docker-usermode-linux
```

Then you can then ssh to it:

```shell
$ ssh root@127.0.0.1 -p 2222
```
Default root password is `voidlinux`.

UML uses `/rootfs` directory as root filesystem, so anything mounted to `/rootfs/*` will be visible inside UML.

To forward ports from UML you need to specify them in `PORTS` env var like:

```
$ docker run -p 2222:22 -p 8080:80 -p 4443:443 --env 'PORTS=22 80 443' --rm juniorjpdj/docker-usermode-linux
```

Port 22 is redirected by default, to not redirect it set `PORTS` to empty:
eg. `--env 'PORTS='`

The same goes for setting memory amount - `MEM` env var sets usable RAM amount. Default is `256M`

eg. `--env MEM=512M`

You can also directly pass arguments to UML kernel:

```shell
$ docker run --rm docker-usermode-linux_uml --help
User Mode Linux v5.10.47-cadey
        available at http://user-mode-linux.sourceforge.net/

--showconfig
    Prints the config file that this UML binary was generated from.

iomem=<name>,<file>
    Configure <file> as an IO memory region named <name>.

mem=<Amount of desired ram>
    This controls how much "physical" memory the kernel allocates
    for the system. The size is specified as a number followed by
    one of 'k', 'K', 'm', 'M', which have the obvious meanings.
    This is not related to the amount of memory in the host.  It can
    be more, and the excess, if it's ever used, will just be swapped out.
        Example: mem=64M

--help
    Prints this message.

[...]
```


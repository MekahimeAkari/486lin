# 486lin (better name pending)
486lin (which isn't a good name) is a livecd/distro thingy for older computers (specifically 486s, like I have) that get generated through these scripts.
The goal is something that can install Gentoo, but at the moment it (at least in qemu) will boot up and dhcp correctly. I still need to test it on my 486.

## Prerequistes
gcc et al, git, lzop, squash/iso tools (possibly more I have forgotten)

## Instructions
Run `./build-dist.sh`. That will build everything and leave you an iso in `build/disk`. For anything else, run `./build-dist.sh -h`.

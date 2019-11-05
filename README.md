This is a [Vagrant](https://www.vagrantup.com/) Environment for creating custom [Debian Live](https://www.debian.org/CD/live/) ISO images.

# Usage

Install the [Base Debian Vagrant Box](https://github.com/rgl/debian-vagrant).

Run `vagrant up builder` to launch the debian live builder. This will build the ISO image and copy it to the current directory as `live-image-amd64.hybrid.iso`.

Run `vagrant up bios` to boot the generated ISO in [BIOS](https://en.wikipedia.org/wiki/BIOS) mode.

Run `vagrant up efi` to boot the generated ISO in [EFI](https://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface) mode.

To build a netboot image, set the `LB_BUILD_TYPE` environment variable to `netboot` before launching vagrant, e.g. `LB_BUILD_TYPE=netboot vagrant up builder`. This will build the netboot image and copy it to the current directory as `live-image-amd64.netboot.tar`.


# Burning the ISO file to a USB pen/disk drive

Use [Etcher](https://www.etcher.io/) to burn the generated `live-image-amd64.hybrid.iso` file to a device (e.g. `sdd`), or use the following commands:

```bash
sudo su -l # enter a root shell
cp live-image-amd64.hybrid.iso /dev/sdd
sync
echo 1 >/sys/block/sdd/device/rescan
fdisk -u -l /dev/sdd
lsblk /dev/sdd
mkdir -p /mnt/sdd1
mount /dev/sdd1 /mnt/sdd1
(cd /mnt/sdd1 && md5sum --quiet --check md5sum.txt)
umount /mnt/sdd1
eject /dev/sdd
```


# Reference

* [Live Systems Manual](https://live-team.pages.debian.net/live-manual/html/live-manual/index.en.html)
* [Debian Live Team Repositories](https://salsa.debian.org/live-team)
* [Debian Live Wiki](http://wiki.debian.org/DebianLive): Information about the Debian Live team and its contacts.

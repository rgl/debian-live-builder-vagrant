This is a [Vagrant](https://www.vagrantup.com/) Environment for creating custom [Debian Live](https://www.debian.org/CD/live/) ISO images.

# Usage

Run `vagrant up builder` to launch the debian live builder. This will build the ISO image and copy it to the current directory as `live-image-amd64.hybrid.iso`.

Run `create_empty_box.sh` to create the `empty` environment (the test machines use it as a base box).

Run `vagrant up bios` to boot the generated ISO in [BIOS](https://en.wikipedia.org/wiki/BIOS) mode.

Run `vagrant up efi` to boot the generated ISO in [EFI](https://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface) mode.


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

* [Live Systems Manual](http://debian-live.alioth.debian.org/live-manual/stable/manual/html/live-manual.en.html)
* [Debian Live Developer Information](http://debian-live.alioth.debian.org/)
* [Debian Live Wiki](http://wiki.debian.org/DebianLive): Information about the Debian Live team and its contacts.

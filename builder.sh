#!/bin/bash
set -eux

echo 'Defaults env_keep += "DEBIAN_FRONTEND"' >/etc/sudoers.d/env_keep_apt
chmod 440 /etc/sudoers.d/env_keep_apt
export DEBIAN_FRONTEND=noninteractive
apt-get update


#
# provision vim.

apt-get install -y --no-install-recommends vim

cat >~/.vimrc <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
EOF


#
# provision git.

apt-get install -y --no-install-recommends git
git config --global user.name 'Rui Lopes'
git config --global user.email 'rgl@ruilopes.com'
git config --global push.default simple


#
# enable wget quiet mode (to disable the process bar).

echo 'quiet=on' >~/.wgetrc


#
# configure the shell.

cat >~/.bash_history <<'EOF'
EOF

cat >~/.bashrc <<'EOF'
# If not running interactively, don't do anything
[[ "$-" != *i* ]] && return
export EDITOR=vim
export PAGER=less
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

cat >~/.inputrc <<'EOF'
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOD": backward-word
"\eOC": forward-word
set show-all-if-ambiguous on
set completion-ignore-case on
EOF


#
# install dependencies.

apt-get install -y dpkg-dev debhelper debootstrap debian-archive-keyring
apt-get install -y libcdio-utils librsvg2-bin pngquant


#
# build and install the debian live-build package from source.

su vagrant <<'VAGRANT'
set -eux

# enable wget quiet mode (to disable the process bar).
echo 'quiet=on' >~/.wgetrc

# clone the live-build repo.
cd ~
git clone git://anonscm.debian.org/git/debian-live/live-build.git
cd live-build
git checkout 6e0b98ce05c1a8e8dd140009cc60c7ea348b6fa1
git rev-parse --abbrev-ref HEAD # branch
git rev-parse HEAD              # revision

# build the package.
dpkg-buildpackage -b -uc -us
VAGRANT

# install the live-build package.
dpkg -i /home/vagrant/live-build_*.deb


#
# build the Debian Standard live image (from the debian branch).
# see lb_config(1)
# NB default images configurations are defined in a branch at https://anonscm.debian.org/git/debian-live/live-images.git/
#    e.g. https://anonscm.debian.org/git/debian-live/live-images.git/tree/images/standard?h=debian
# NB by default we do not build this, this is here as an example on how to build the standard image.

if false; then
mkdir live-images && pushd live-images
lb config --config git://anonscm.debian.org/git/debian-live/live-images.git::debian
cd images/standard
# always disable the creation of the source tarball (e.g. live-image-source.debian.tar)
# because it takes a bit of time to complete and we do not really use it.
sed -i -E 's,(\s*--source ).*,\1false \\,' auto/config
lb config
lb build
popd
fi


#
# build a custom live image.

mkdir custom-image && pushd custom-image

# configure it.
# see http://debian-live.alioth.debian.org/live-manual/stable/manual/html/live-manual.en.html
# see lb(1)
# see live-build(7)
# see lb_config(1)
# NB default images configurations are defined in a branch at https://anonscm.debian.org/git/debian-live/live-images.git/
#    e.g. https://anonscm.debian.org/git/debian-live/live-images.git/tree/images/standard?h=debian

mkdir -p auto
cp /usr/share/doc/live-build/examples/auto/* auto/

cat >auto/config <<'EOF'
#!/bin/sh
set -eux
lb config noauto \
    --binary-images iso-hybrid \
    --mode debian \
    --distribution stretch \
    --architectures amd64 \
    --bootappend-live 'boot=live components username=vagrant' \
    --mirror-bootstrap http://ftp.pt.debian.org/debian/ \
    --mirror-binary http://ftp.pt.debian.org/debian/ \
    --apt-indices false \
    --memtest none \
    "${@}"
EOF
# NB --bootappend-live '... keyboard-layouts=pt' is currently broken. we have to manually configure the keyboard.
#    see Re: Status of kbd console-data and console-setup at https://lists.debian.org/debian-devel/2016/08/msg00276.html
chmod +x auto/config

mkdir -p config/package-lists
cat >config/package-lists/custom.list.chroot <<'EOF'
console-data
debconf-utils
openssh-server
less
vim
tcpdump
qemu-utils
ntfs-3g
hdparm
usbutils
EOF

mkdir -p config/preseed
cat >config/preseed/keyboard.cfg.chroot <<'EOF'
# format: <owner> <question name> <question type> <value>
# NB put just a single space or tab between <question type> and <value>.
# NB this will be eventually stored at /var/cache/debconf/config.dat
console-common  console-data/keymap/policy  select Select keymap from full list
console-common  console-data/keymap/full    select pt-latin1
EOF

mkdir -p config/includes.chroot/lib/live/config
cat >config/includes.chroot/lib/live/config/0149-keyboard <<'EOF'
#!/bin/sh
set -eux
dpkg-reconfigure console-common
EOF
chmod +x config/includes.chroot/lib/live/config/0149-keyboard

mkdir -p config/includes.chroot/etc
cat >config/includes.chroot/etc/motd <<'EOF'

Enter a root shell with:

    sudo su -l

Change the keyboard layout with one of:

    sudo loadkeys pt-latin1
    sudo loadkeys us

List disks:

    lsblk -O
    lsblk -x KNAME -o KNAME,SIZE,TRAN,SUBSYSTEMS,FSTYPE,UUID,LABEL,MODEL,SERIAL

EOF

mkdir -p config/includes.chroot/etc/profile.d
cat >config/includes.chroot/etc/profile.d/login.sh <<'EOF'
[[ "$-" != *i* ]] && return
export EDITOR=vim
export PAGER=less
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

cat >config/includes.chroot/etc/inputrc <<'EOF'
set input-meta on
set output-meta on
set show-all-if-ambiguous on
set completion-ignore-case on
"\e[A": history-search-backward
"\e[B": history-search-forward
"\eOD": backward-word
"\eOC": forward-word
EOF

mkdir -p config/includes.chroot/etc/vim
cat >config/includes.chroot/etc/vim/vimrc.local <<'EOF'
syntax on
set background=dark
set esckeys
set ruler
set laststatus=2
set nobackup
EOF

mkdir -p config/hooks/normal
cat >config/hooks/normal/9990-vagrant-user.hook.chroot <<'EOF'
#!/bin/sh
set -eux

# create the vagrant user and group.
adduser --gecos '' --disabled-login vagrant
echo vagrant:vagrant | chpasswd -m

# let him use root permissions without sudo asking for a password.
echo 'vagrant ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/vagrant

# install the vagrant public key.
# NB vagrant will replace this insecure key on the first vagrant up.
install -d -m 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget -q --no-check-certificate https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -O authorized_keys
chmod 600 authorized_keys
chown -R vagrant:vagrant .
EOF

cat >config/hooks/normal/9990-initrd.hook.chroot <<'EOF'
#!/bin/sh
set -eux
echo nls_ascii >>etc/initramfs-tools/modules # for booting from FAT32.
EOF

cat >config/hooks/normal/9990-bootloader-splash.hook.binary <<'EOF'
#!/bin/sh
set -eux
rsvg-convert --format png --width 640 --height 480 /vagrant/bootloader-splash.svg -o isolinux/splash.png
pngquant --ext .png --force isolinux/splash.png
EOF

cat >config/hooks/normal/9990-bootloader-menu.hook.binary <<'EOF'
#!/bin/sh
set -eux
sed -i -E 's,^(set default=.+),\1\nset timeout=5,' boot/grub/grub.cfg
sed -i -E 's,^(timeout ).+,\150,' isolinux/isolinux.cfg
rm isolinux/advanced.cfg
cat >isolinux/menu.cfg <<'EOM'
menu hshift 0
menu width 82
include stdmenu.cfg
include live.cfg
menu separator
label hdt
	menu label ^Hardware Detection Tool (HDT)
	com32 hdt.c32
menu clear
EOM
EOF

chmod +x config/hooks/normal/*.hook.*

# build it.
lb build

# show some information about the generated iso file.
fdisk -l live-image-amd64.hybrid.iso
iso-info live-image-amd64.hybrid.iso --no-header
#iso-info live-image-amd64.hybrid.iso --no-header -f | sed '0,/ISO-9660 Information/d' | sort -k 2

# copy it on the host fs (it will be used by the target VM).
cp live-image-amd64.hybrid.iso /vagrant

# clean it.
#lb clean
#lb clean --purge

# add it to local git repository.
git init
cp /usr/share/doc/live-build/examples/gitignore .gitignore
echo 'chroot.files' >>.gitignore
echo 'live-image-*' >>.gitignore
git add .
git commit -m 'Init.'

popd

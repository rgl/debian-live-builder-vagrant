#!/bin/bash
set -eu

rm -rf tmp-empty-box 
mkdir -p tmp-empty-box
pushd tmp-empty-box

# create and add an empty box to the libvirt provider.
TEMPLATE_BOX=~/.vagrant.d/boxes/debian-12-amd64/0.0.0/libvirt
if [ ! -d ~/.vagrant.d/boxes/empty/0.0.0/libvirt ] && [ -d "$TEMPLATE_BOX" ]; then
rm -f *
cp "$TEMPLATE_BOX/Vagrantfile" .
echo '{"format":"qcow2","provider":"libvirt","virtual_size":10}' >metadata.json
qemu-img create -f qcow2 box.img 10G
tar cvzf empty.box metadata.json Vagrantfile box.img
vagrant box add --force empty empty.box
fi

popd
rm -rf tmp-empty-box

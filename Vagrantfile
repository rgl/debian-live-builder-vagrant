Vagrant.configure('2') do |config|
  config.vm.provider :virtualbox do |vb|
    vb.linked_clone = true
    vb.memory = 2048
    vb.customize ['modifyvm', :id, '--cableconnected1', 'on']
  end

  config.vm.define :builder do |config|
    config.vm.box = 'ubuntu-16.04-amd64'
    config.vm.hostname = 'builder'
    config.vm.provision :shell, path: 'builder.sh'
  end

  ['bios', 'efi'].each do |firmware|
    config.vm.define firmware do |config|
      config.vm.box = 'empty'
      config.vm.synced_folder '.', '/vagrant', disabled: true
      config.vm.provider :virtualbox do |vb|
        vb.check_guest_additions = false
        vb.functional_vboxsf = false
        vb.customize ['modifyvm', :id, '--firmware', firmware]
        vb.customize ['storageattach', :id,
          '--storagectl', 'IDE Controller',
          '--device', '0',
          '--port', '1',
          '--type', 'dvddrive',
          '--tempeject', 'on',
          '--medium', 'live-image-amd64.hybrid.iso']
      end
    end
  end
end

# to make sure the nodes are created sequentially, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure('2') do |config|
  config.vm.provider :libvirt do |lv, config|
    lv.memory = 2048
    lv.cpus = 2
    lv.cpu_mode = 'host-passthrough'
    # lv.nested = true
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs'
  end

  config.vm.provider :virtualbox do |vb|
    vb.linked_clone = true
    vb.memory = 2048
    vb.customize ['modifyvm', :id, '--cableconnected1', 'on']
  end

  config.vm.define :builder do |config|
    config.vm.box = 'debian-10-amd64'
    config.vm.hostname = 'builder'
    config.vm.provision :shell, path: 'builder.sh', env: {'LB_BUILD_TYPE' => ENV['LB_BUILD_TYPE'] || 'iso'}
  end

  ['bios', 'efi'].each do |firmware|
    config.vm.define firmware do |config|
      config.vm.box = 'empty'
      config.vm.provider :libvirt do |lv, config|
        lv.loader = '/usr/share/ovmf/OVMF.fd' if firmware == 'efi'
        lv.boot 'cdrom'
        lv.storage :file, :device => :cdrom, :path => "#{Dir.pwd}/live-image-amd64.hybrid.iso"
        config.vm.synced_folder '.', '/vagrant', disabled: true
      end
      config.vm.provider :virtualbox do |vb, config|
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
        config.vm.synced_folder '.', '/vagrant', disabled: true
      end
    end
  end

  config.trigger.before :up do |trigger|
    trigger.only_on = ['bios', 'efi']
    trigger.run = {inline: './create_empty_box.sh'}
  end
end

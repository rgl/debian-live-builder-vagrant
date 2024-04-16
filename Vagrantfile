# to make sure the nodes are created sequentially, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure('2') do |config|
  config.vm.provider :libvirt do |lv, config|
    lv.memory = 2 * 1024
    lv.cpus = 4
    lv.cpu_mode = 'host-passthrough'
    # lv.nested = true # nested virtualization.
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs', nfs_version: '4.2', nfs_udp: false
  end

  config.vm.provider :hyperv do |hv, config|
    hv.linked_clone = true
    hv.memory = 2 * 1024
    hv.cpus = 4
    # hv.enable_virtualization_extensions = true # nested virtualization.
    hv.vlan_id = ENV['HYPERV_VLAN_ID']
    # see https://github.com/hashicorp/vagrant/issues/7915
    # see https://github.com/hashicorp/vagrant/blob/10faa599e7c10541f8b7acf2f8a23727d4d44b6e/plugins/providers/hyperv/action/configure.rb#L21-L35
    config.vm.network :private_network, bridge: ENV['HYPERV_SWITCH_NAME'] if ENV['HYPERV_SWITCH_NAME']
    config.vm.synced_folder '.', '/vagrant',
      type: 'smb',
      smb_username: ENV['VAGRANT_SMB_USERNAME'] || ENV['USER'],
      smb_password: ENV['VAGRANT_SMB_PASSWORD']
  end

  config.vm.define :builder do |config|
    config.vm.box = 'debian-12-amd64'
    config.vm.hostname = 'builder'
    config.vm.provision :shell, path: 'builder.sh', env: {
      'LB_BUILD_TYPE' => ENV['LB_BUILD_TYPE'] || 'iso',
      'LB_BUILD_ARCH' => ENV['LB_BUILD_ARCH'] || 'amd64',
    }
  end

  ['bios', 'efi'].each do |firmware|
    config.vm.define firmware do |config|
      config.vm.box = 'empty'
      config.vm.provider :libvirt do |lv, config|
        lv.loader = '/usr/share/ovmf/OVMF.fd' if firmware == 'efi'
        lv.boot 'cdrom'
        lv.storage :file, :device => :cdrom, :bus => 'sata', :path => "#{Dir.pwd}/live-image-amd64.hybrid.iso"
        lv.graphics_type = 'spice'
        lv.video_type = 'virtio'
        config.vm.synced_folder '.', '/vagrant', disabled: true
      end
    end
  end

  config.trigger.before :up do |trigger|
    trigger.only_on = ['bios', 'efi']
    trigger.run = {inline: './create_empty_box.sh'}
  end
end

Vagrant.configure('2') do |config|
    config.vm.box = 'ubuntu/trusty32'
    config.vm.network :private_network, ip: '10.2.2.10'
    config.vm.synced_folder '.chef/', '/tmp/.chef'
    config.vm.provider 'virtualbox' do |vb|
        vb.memory = 512
    end
    config.omnibus.chef_version = '11.16.0'
    config.librarian_chef.cheffile_dir = '.chef'
    config.vm.provision 'chef_solo' do |chef|
        chef.log_level = 'info'
        chef.custom_config_path = '.chef/solo.rb'
        chef.cookbooks_path = ['.chef/cookbooks', '.chef/site-cookbooks']
        chef.json.merge!(JSON.parse(IO.read('.chef/nodes/10.2.2.10.json')))
    end
end

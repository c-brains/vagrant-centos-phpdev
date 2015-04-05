# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "opscode-centos-7.0"
  config.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-7.0_chef-provisionerless.box"
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  # VBoxAddition を更新すると、共有フォルダが使えなくなるので更新しない
  config.vbguest.auto_update = false

  config.vm.define :develop do |develop|
    develop.vm.hostname = "develop"
    develop.vm.network :private_network, ip: "192.168.33.10"

    #develop.vm.synced_folder "application", "/var/www/application",
    #  :nfs => false,
    #  :owner => "vagrant",
    #  :group => "apache",
    #  :mount_options => ["dmode=775,fmode=775"]
    develop.vm.synced_folder "application", "/var/www/application",
      type: "rsync",
      rsync__args: ["--verbose", "--archive", "-z", "--chmod=g+w"],
      owner: "vagrant",
      group: "apache",
      rsync__auto: true,
      rsync__chown: true
  end

  config.vm.provision :itamae do |config|
    config.sudo = true

    # recipes(String or Array)
    config.recipes = ['./itamae/recipe.rb']

    config.json = './itamae/node.json'
  end
end

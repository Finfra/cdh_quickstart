# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
system('[ ! -d forVm ] && mkdir forVm')

Vagrant.configure(2) do |config|
  config.vm.define "cdh6" do |devbox|
    devbox.vm.box = "generic/centos7"
    devbox.vm.network "private_network", ip: "172.1.2.3"
    devbox.vm.hostname = "cdh6"
    devbox.vm.provision "shell", path: "scripts/install.sh"
        # config.vm.synced_folder "~/work-terraform/", "/home/vagrant/forVm"


    devbox.vm.provider "virtualbox" do |v|
      v.memory = 6144
      v.cpus = 3
    end
  end
end
    

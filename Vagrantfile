# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  ## Lets lower the memory consumption some
  config.vm.provider :virtualbox do |virtualbox|
    virtualbox.name = "Rubeez!"
    virtualbox.customize ["modifyvm", :id, "--memory", "512"]
  ## Limit the number of CPUs.
  # virtualbox.customize ["modifyvm", :id, "--cpus", "2"]
  ## Limit the max CPU usage.
  # virtualbox.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
  end  

  ## Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "precise"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.network :public_network
  config.vm.provision :shell, :inline => "apt-get update; apt-get install -y ruby1.9.3 build-essential libxml2-dev libxslt-dev; cd /vagrant; sudo gem build /vagrant/rubeez.gemspec; sudo gem install /vagrant/rubeez-0.1.gem --no-rdoc --no-ri"
end

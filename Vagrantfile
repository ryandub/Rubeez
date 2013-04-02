# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  # Lets lower the memory consumption some
  config.vm.customize ["modifyvm", :id, "--memory", 512]

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "precise"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.provision :shell, :inline => "apt-get update; apt-get install -y ruby1.9.3 build-essential libxml2-dev libxslt-dev; sudo gem build /vagrant/rubeez.gemspec; sudo gem install /vagrant/rubeez-0.1.gem --no-rdoc --no-ri"
end

require 'rubeez'
require 'rubeez/application'
require 'rubeez/log'
require 'net/ssh'
require 'fog'

module Rubeez
  class Swarm

    def initialize
      super
    end

    def create_connection
      connection = Fog::Compute.new({
        :provider           => 'Rackspace',
        :rackspace_username => Rubeez::Config[:username],
        :rackspace_api_key  => Rubeez::Config[:apikey],
        :version => :v2
      })
      return connection
    end

    def create_keys
      unless File.exists?(File.expand_path("~/.ssh/fog_rsa")) and File.exists?(File.expand_path("~/.ssh/fog_rsa.pub"))
        key = OpenSSL::PKey::RSA.new 2048
        type = key.ssh_type
        
        data = [ key.to_blob ].pack('m0')
        
        File.open(File.expand_path('~/.ssh/fog_rsa'), 'w') do |f|
          f.puts "#{key}"
        end
        
        File.open(File.expand_path('~/.ssh/fog_rsa.pub'), 'w') do |f|
          f.puts "#{type} #{data}"
        end
      end
    end 

    def create_bee(connection, name)
      bee = connection.servers.create(
              :name => name,
              :flavor_id => connection.flavors.first.id,
              :image_id => connection.images.find {|img| img.name =~ /Ubuntu 12.04/}.id,
              :public_key_path => '~/.ssh/fog_rsa.pub',
              :private_key_path => '~/.ssh/fog_rsa'
              )
      Rubeez::Log.info("Adding #{bee.name} to the swarm.")
      write_file(Rubeez::Config[:rubeez_file], bee.id)
      return bee
    end

    def create_swarm
      beez = []
      threads = []
      connection = create_connection
      create_keys
      Rubeez::Log.info("Populating hive - this may take some time")
      Rubeez::Log.info("-----------------------------------------")
      Rubeez::Config[:beez].to_i.times do |i|
	Rubeez::Log.info("Creating bee ##{i}")
        threads[i] = Thread.new do        
                       bee = create_bee(connection, "rubeez-worker-n#{i}")
                       beez << bee
                     end 
      end
      threads.each do |t|
        t.join
      end
      Rubeez::Log.info("Swarm Created: #{beez.each {|bee| print bee.name + "\n"}}")
    end

    def read_file(file)
      contents = Array.new
      f = File.open(File.expand_path(file))
      contents = f.each_line { |line| }
      return contents
    end

    def swarm
      create_swarm
    end

    def status
      beez = read_file(Rubeez::Config[:rubeez_file])
    end

    def write_file(file, data)
      File.open(File.expand_path(file), 'a') {|f| f.write(data + "\n") }
    end

  end
end

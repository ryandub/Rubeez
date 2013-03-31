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

    def check_swarm_exists?
      if ((File.size?(Rubeez::Config[:rubeez_file]) > 0) rescue false)
        Rubeez::Log.info("Swarm already exists. Run 'rubeez kill' to delete servers and start new swarm.")
	      exit
      end
    end

    def clear_file(file)
      File.open(file, 'w') {}
    end

    def create_connection
      connection = Fog::Compute.new({
        :provider           => 'Rackspace',
        :rackspace_username => Rubeez::Config[:username],
        :rackspace_api_key  => Rubeez::Config[:apikey],
#        :rackspace_region   => Rubeez::Config[:region],
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
      check_swarm_exists?
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

    def kill_swarm
      connection = create_connection
      beez = read_file(Rubeez::Config[:rubeez_file])
      connection = create_connection
      Rubeez::Log.info("Killing hive...")
      beez.each do |bee|
        Rubeez::Log.info("#{connection.servers.delete(bee)}")
      end      
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
      beez = IO.readlines Rubeez::Config[:rubeez_file]
      connection = create_connection
      beez.each do |id|
        bee = connection.servers.get(id.strip)
        Rubeez::Log.info("#{bee.name}: #{bee.state} - #{bee.progress}")
      end             
    end

    def write_file(file, data)
      File.open(File.expand_path(file), 'a') {|f| f.write(data + "\n") }
    end
  end
end

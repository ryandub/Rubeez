# The MIT License

# Copyright (c) 2013 Ryan Walker 

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


require 'rubeez'
require 'rubeez/application'
require 'rubeez/log'
require 'net/ssh'
require 'ruport'
require 'csv'
require 'fog'

module Rubeez
  class Swarm

    def initialize
      super
    end

    def attack
      threads = Array.new
      check_swarm_exists?
      check_url
      load_keys
      cmd = attack_command
      connection = create_connection
      beez = read_file(Rubeez::Config[:rubeez_file])
      beez.count.times do |i|
        threads[i] = Thread.new do
          server = connection.servers.get(beez[i])
          output = server.ssh(['chmod +x /tmp/rubeez_prepare.sh && bash /tmp/rubeez_prepare.sh', cmd], 
                               :key_data => Rubeez::Config[:private_key_data].to_s)
          Rubeez::Log.info("#{server.name}: Completed Attack")
        end
      end
      threads.each do |t|
        t.join
      end
      results = gather_reports
      Rubeez::Log.info("Results averaged across the entire swarm:")
      print_results(results)
      clean_up
    end

    def attack_command
      get_headers
      cmd = "ab -e /tmp/rubeez.out -r -n #{Rubeez::Config[:requests]} -c #{Rubeez::Config[:concurrency]} -C 'sessionid=SomeSessionID' #{Rubeez::Config[:header_string]} '#{Rubeez::Config[:url]}'"
      Rubeez::Log.info("Attacking #{Rubeez::Config[:url]} with the following command:")
      Rubeez::Log.info("#{cmd}")
      Rubeez::Log.info("If this is your first attack with this swarm, it may take a few minutes before starting")
      return cmd
    end
    
    def check_swarm_exists?
      if ((File.size?(Rubeez::Config[:rubeez_file]) > 0) rescue false)
        return true
      else
        swarm_no_exist
      end
    end

    def check_url
      uri = URI(Rubeez::Config[:url])
      if not uri.scheme
        uri = URI("http://" + Rubeez::Config[:url])
      end
      uri.path = "/" if uri.path.empty?
      Rubeez::Config[:url] = uri.to_s
    end

    def clean_up
      beez = read_file(Rubeez::Config[:rubeez_file])
      files = beez.map {|x| "/tmp/#{x}.out"}
      Rubeez::Log.debug("Removing local results files")
      files.each do |file|
        File.delete(file)
        Rubeez::Log.debug("Deleted #{file}")
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
      unless File.exists?(File.expand_path(Rubeez::Config[:private_key])) and File.exists?(File.expand_path(Rubeez::Config[:public_key]))
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
      load_keys
      bee = connection.servers.create(
              :name => name,
              :flavor_id => connection.flavors.first.id,
              :image_id => connection.images.find {|img| img.name =~ /Ubuntu 12.04/}.id,
              :personality => [{
                                :path => '/root/.ssh/authorized_keys',
                                :contents => Base64.encode64(Rubeez::Config[:public_key_data].to_s)
                              },
                              {
                                :path => '/tmp/rubeez_prepare.sh',
                                :contents => Base64.encode64("#! /bin/bash\nif [ ! -f /tmp/rubeez_ready ]; then\napt-get update\napt-get install -y apache2-utils\ntouch /tmp/rubeez_ready\nfi")
                              }]
              )
      Rubeez::Log.info("Adding #{bee.name} to the swarm.")
      write_file(Rubeez::Config[:rubeez_file], bee.id)
      return bee
    end

    def create_swarm
      beez = []
      threads = []
      if ((File.size?(Rubeez::Config[:rubeez_file]) > 0) rescue false)
        Rubeez::Log.info("Swarm already exists. Run 'rubeez --kill' to delete servers and start new swarm.")
        exit
      end
      connection = create_connection
      create_keys
      Rubeez::Log.info("Populating swarm - this may take some time")
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
      Rubeez::Log.info("Swarm Created:")
      beez.each {|bee| Rubeez::Log.info("#{bee.name}: #{bee.id}")}
      Rubeez::Log.info("Use 'rubeez -s' to check status.")
    end

    def gather_reports
      threads = Array.new
      beez = read_file(Rubeez::Config[:rubeez_file])
      connection = create_connection
      beez.count.times do |i|
        threads[i] = Thread.new do
                       server = connection.servers.get(beez[i])
                       Fog::SCP.new(server.ipv4_address, 'root', 
                                    {:key_data => Rubeez::Config[:private_key_data].to_s}).download(
                                    '/tmp/rubeez.out', "/tmp/#{beez[i]}.out", {})
                     end
      end
      threads.each do |t|
        t.join
      end
      files = beez.map {|x| "/tmp/#{x}.out"}
      data = Array.new
      files.each do |file|
        data << CSV.read(file)
      end
      average = data[0]
      data[0].count.times do |j|
        unless data[0][j][0].include?('Percentage')
          c = Array.new
          data.each do |file|
            unless c[j].nil?
              c[j] << file[j][1]
            else
              c[j] = *file[j][1]
            end
          end
          average[j][1] = c[j]
        end
      end

      average.count.times do |i|
        unless average[i][0].include?('Percentage')
          average[i][1].count.times do |j|
            average[i][1][j] = average[i][1][j].to_f
          end
          average[i][1] = average[i][1].instance_eval { reduce(:+) / size.to_f }.round(4)
        end
      end

      return average
    end

    def get_headers
      Rubeez::Config[:header_string] = ''
      if Rubeez::Config[:headers] != ''
          Rubeez::Config[:header].split(';').each do |header|
            Rubeez::Config[:header_string] += ' -H ' + header
          end
      end
    end

    def kill_swarm
      threads = Array.new
      connection = create_connection
      beez = read_file(Rubeez::Config[:rubeez_file])
      connection = create_connection
      Rubeez::Log.info("Killing swarm...")
      beez.count.times do |i|
        threads[i] = Thread.new do
          connection.servers.destroy(beez[i])
          Rubeez::Log.info("Killed bee #{beez[i]}")
        end
      end
      threads.each do |t|
        t.join
      end
      clear_file(Rubeez::Config[:rubeez_file])
      Rubeez::Log.info("Swarm killed.")
    end

    def load_keys
      Rubeez::Config[:private_key_data] = File.read File.expand_path(Rubeez::Config[:private_key])
      Rubeez::Config[:public_key_data] =  File.read File.expand_path(Rubeez::Config[:public_key])
    end

    def print_results(results)
      table = Table(%w[percentage_served time_in_ms])
      results.drop(1).each do |row|
        table << { "percentage_served" => row[0], "time_in_ms" => row[1] }
      end
      Rubeez::Log.info("\n#{table.to_text}")
    end

    def read_file(file)
      contents = Array.new
      contents = IO.readlines file
      contents.each do |line|
        line.strip!
      end
      return contents
    end

    def status
      status = Array.new
      check_swarm_exists?
      beez = read_file(Rubeez::Config[:rubeez_file])
      connection = create_connection
      beez.each do |id|
        bee = connection.servers.get(id)
        status << bee.state
        Rubeez::Log.info("#{bee.name}: #{bee.state} - #{bee.progress}")
      end
      unless status.include?("BUILD") or status.include?("ERROR")
        Rubeez::Log.info("All beez ready! Swarm is complete. Run 'rubeez --attack --url [TARGET]'")
      else
        Rubeez::Log.info("Swarm still forming. #{status.count {|x| x == 'ACTIVE'}} out of #{status.count} complete.")
      end
    end

    def swarm
      create_swarm
    end

    def swarm_no_exist
      Rubeez::Log.info("Swarm has not been populated yet. Run rubeez -u [USERNAME] -a [APIKEY] -b [NUM_OF_BEEZ] to create it.")
      exit
    end

    def swarm_not_ready
      Rubeez::Log.info("Swarm not fully populated. Run 'rubeez -s' for status.")
      exit
    end

    def swarm_ready?
      if check_swarm_exists?
        state = Array.new
        connection = create_connection
        beez = read_file(Rubeez::Config[:rubeez_file])
        beez.each do |id|
          bee = connection.servers.get(id)
          if !bee.ready?
            swarm_not_ready
          end
        end
      else
        swarm_no_exist
      end
    end

    def write_file(file, data)
      File.open(File.expand_path(file), 'a') {|f| f.write(data + "\n") }
    end
  end
end

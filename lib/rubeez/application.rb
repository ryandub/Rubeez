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
require 'rubeez/swarm'
require 'rubeez/log'
require 'mixlib/cli'

class Rubeez::Application
  include Mixlib::CLI

  option :username,
    :short => "-u USERNAME",
    :long => "--username USERNAME",
    :required => true,
    :description => "Rackspace Cloud Username"

  option :apikey,
    :short => "-k APIKEY",
    :long => "--apikey APIKEY",
    :required => true,
    :description => "Rackspace Cloud APIKEY"

  option :beez,
    :short => "-b NUMBER_OF_BEEZ",
    :long => "--beez NUMBER_OF_BEEZ",
    :default => "5",
    :description => "Number of beez (servers) to create"

  option :region,
    :short => "-r REGION",
    :long => "--region REGION",
    :default => "ord",
    :description => "Region to deploy into (dfw, ord, lon)"

  option :status,
    :short => "-s",
    :long => "--status",
    :description => "Show swarm status"

  option :kill,
    :long => "--kill",
    :description => "Kill the entire swarm"

  option :attack,
    :long => "--attack",
    :description => "Attack URL designated by --url"

  option :url,
    :long => "--url [URL]",
    :description => "URL to attack"

  option :requests,
    :long => "--requests [REQUESTS]",
    :short => "-q [REQUESTS]",
    :description => "Number of requests each bee will make.",
    :default => "100"

  option :concurrency,
    :long => "--concurrency [CONCURRENCY]",
    :short => "-c [CONCURRENCY]",
    :description => "Number of concurrent connections each bee will use.",
    :default => "10"


  def initialize
    super
  end

  def run
    configure_rubeez
    configure_logging
    run_application
  end

  def configure_rubeez
    @attributes = parse_options
    Rubeez::Config.merge!(config)
  end

  def configure_logging
    Rubeez::Log.init(Rubeez::Config[:log_location])
    Rubeez::Log.level = Rubeez::Config[:log_level]
  end

  def run_application
    rubeez = Rubeez::Swarm.new
    if Rubeez::Config[:status]
      rubeez.status
      exit 0
    end
    if Rubeez::Config[:kill]
      rubeez.kill_swarm
      exit 0
    end
    if Rubeez::Config[:attack]
      if Rubeez::Config[:url]
        rubeez.attack
        exit 0
      else
        Rubeez::Log.info("No url specified. Use --url [URL]")
      end
    end
    rubeez.swarm
  end
end

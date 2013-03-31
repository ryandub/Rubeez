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

  option :time,
    :short => "-t SECONDS",
    :long => "--time SECONDS",
    :default => "600",
    :description => "Duration of test in seconds"

  option :region,
    :short => "-r REGION",
    :long => "--region REGION",
    :default => "ord",
    :description => "Region to deploy into (dfw, ord, lon)"

  option :status,
    :short => "-s",
    :long => "--status",
    :description => "Show swarm status"

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
    rubeez.swarm
  end

end

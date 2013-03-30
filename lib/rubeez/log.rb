require 'rubeez/config'
require 'mixlib/log'

module Rubeez
  class Log
    extend Mixlib::Log

    init(Rubeez::Config[:log_location])
    level = Rubeez::Config[:log_level]

  end
end

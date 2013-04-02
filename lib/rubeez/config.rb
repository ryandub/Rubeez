require 'mixlib/config'

module Rubeez
  class Config
    extend Mixlib::Config

    log_level :debug
    log_location STDOUT
    region :ord
    rubeez_file File.expand_path('~/.rubeez')
    private_key File.expand_path('~/.ssh/fog_rsa')
    public_key File.expand_path('~/.ssh/fog_rsa.pub')
    headers ""
  end
end

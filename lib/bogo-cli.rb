require 'bogo'
require 'bogo-config'

module Bogo
  module Cli
    autoload :Command, 'bogo-cli/command'
    autoload :Setup, 'bogo-cli/setup'
  end
end

require 'bogo-cli/version'

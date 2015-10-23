require 'bogo'
require 'slop'
require 'bogo-config'

module Bogo
  module Cli
    autoload :Command, 'bogo-cli/command'
    autoload :Setup, 'bogo-cli/setup'

    class << self
      attr_accessor :exit_on_signal
    end

  end
end

require 'bogo-cli/version'

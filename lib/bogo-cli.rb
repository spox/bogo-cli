module Bogo
  module Cli
    autoload :Command, 'bogo-cli/command'
    autoload :Parser, 'bogo-cli/parser'
    autoload :Setup, 'bogo-cli/setup'
    autoload :VERSION, 'bogo-cli/version'

    class << self
      attr_accessor :exit_on_signal
    end
  end
end

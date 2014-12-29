require 'slop'
require 'bogo-cli'

module Bogo
  module Cli
    class Setup
      class << self

        # Wrap slop setup for consistent usage
        #
        # @yield Slop setup block
        # @return [TrueClass]
        def define(&block)
          begin
            Slop.parse(:help => true) do
              instance_exec(&block)
            end
          rescue => e
            if(ENV['DEBUG'])
              $stderr.puts "ERROR: #{e.class}: #{e}\n#{e.backtrace.join("\n")}"
            end
            exit -1
          end
          true
        end

      end
    end
  end
end

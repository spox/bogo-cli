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
          rescue StandardError, ScriptError => e
            if(ENV['DEBUG'])
              $stderr.puts "ERROR: #{e.class}: #{e}\n#{e.backtrace.join("\n")}"
            else
              $stderr.puts "ERROR: #{e.class}: #{e}"
            end
            exit e.respond_to?(:exit_code) ? e.exit_code : -1
          end
          true
        end

      end
    end
  end
end

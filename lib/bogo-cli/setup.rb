# Trigger shutdown on INT or TERM signals
o_int = Signal.trap('INT'){
  o_int.call if o_int.respond_to?(:call)
  if(Bogo::Cli.exit_on_signal == false)
    Thread.main.raise SignalException.new('SIGINT')
  else
    exit 0
  end
}

o_term = Signal.trap('TERM'){
  o_int.call if o_int.respond_to?(:call)
  if(Bogo::Cli.exit_on_signal == false)
    Thread.main.raise SignalException.new('SIGTERM')
  else
    exit 0
  end
}

require 'bogo-cli'

class Slop
  def bogo_cli_run(*args, &block)
    slop_run(*args, &block)
    old_runner = @runner
    @runner = proc{|*args| old_runner.call(*args); exit 0}
  end
  alias_method :slop_run, :run
  alias_method :run, :bogo_cli_run
  class Option
    def default?
      @value.nil?
    end
  end
end

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
            slop_result = Slop.parse(:help => true) do
              instance_exec(&block)
            end
            puts slop_result.help
            exit -1
          rescue StandardError, ScriptError => e
            if(ENV['DEBUG'])
              $stderr.puts "ERROR: #{e.class}: #{e}\n#{e.backtrace.join("\n")}"
            else
              $stderr.puts "ERROR: #{e.class}: #{e.message}"
            end
            exit e.respond_to?(:exit_code) ? e.exit_code : -1
          end
          true
        end

      end
    end
  end
end

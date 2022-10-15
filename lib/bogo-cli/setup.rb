# Trigger shutdown on INT or TERM signals
o_int = Signal.trap("INT") {
  o_int.call if o_int.respond_to?(:call)
  if Bogo::Cli.exit_on_signal == false
    Thread.main.raise SignalException.new("SIGINT")
  else
    exit 0
  end
}

o_term = Signal.trap("TERM") {
  o_term.call if o_term.respond_to?(:call)
  if Bogo::Cli.exit_on_signal == false
    Thread.main.raise SignalException.new("SIGTERM")
  else
    exit 0
  end
}

module Bogo
  module Cli
    class Setup
      class << self

        # Wrap parsing setup for consistent usage
        #
        # @yield CLI setup block
        # @return [TrueClass]
        def define(&block)
          begin
            result = Parser.parse(help: true) do
              instance_exec(&block)
            end
            puts result.help
            exit 255
          rescue StandardError, ScriptError => err
            err_msg = err.message
            if err.respond_to?(:original) && err.original
              err_msg << "\n#{err.original.message}"
            end
            output_error err_msg
            if ENV["DEBUG"] || ENV["DEBUG_BACKTRACE"]
              output_debug "Stacktrace: #{err.class}: " \
                           "#{err.message}\n#{err.backtrace.join("\n")}"
              if err.respond_to?(:original) && err.original
                msg = "Original Stacktrace: #{err.original.class}: " \
                "#{err.original.message}\n#{err.original.backtrace.join("\n")}"
                output_debug msg
              end
            end
            exit err.respond_to?(:exit_code) ? err.exit_code : -1
          end
          true
        end

        # Write error message to UI. Uses formatted
        # ui if available and falls back to stderr.
        #
        # @param string [String]
        def output_error(string)
          if Command.ui
            Command.ui.error string
          else
            $stderr.puts "ERROR: #{string}"
          end
        end

        # Write debug message to UI. Uses formatted
        # ui if available and falls back to stderr.
        #
        # @param string [String]
        def output_debug(string)
          if Command.ui
            Command.ui.debug string
          else
            $stderr.puts "DEBUG: #{string}"
          end
        end
      end
    end
  end
end

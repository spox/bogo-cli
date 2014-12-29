require 'bogo-ui'
require 'bogo-config'
require 'bogo-cli'

module Bogo
  module Cli
    # Abstract command class
    class Command

      # @return [Hash] options
      attr_reader :options
      # @return [Array] cli arguments
      attr_reader :arguments
      # @return [Ui]
      attr_reader :ui

      # Build new command instance
      #
      # @return [self]
      def initialize(opts, args)
        @options = opts.to_smash
        @arguments = args
        @ui = Ui.new(
          opts.fetch(
            :app_name,
            self.class.name.split('::').first
          )
        )
        load_config!
      end

      # Execute the command
      #
      # @return [TrueClass]
      def execute!
        raise NotImplementedError
      end

      protected

      # Command specific options
      #
      # @return [Hash]
      def opts
        options.fetch(self.class.name.split('::').last.downcase, {})
      end

      # Load configuration file and merge opts
      # on top of file values
      #
      # @return [Hash]
      def load_config!
        if(options[:config])
          config = Bogo::Config.new(options[:config])
        elsif(self.class.const_defined?(:DEFAULT_CONFIGURATION_FILES))
          path = self.class.const_get(:DEFAULT_CONFIGURATION_FILES).detect do |check|
            full_check = File.expand_path(check)
            File.exists?(full_check)
          end
          config = Bogo::Config.new(path) if path
        end
        if(config)
          @options = config.to_smash.deep_merge(options.to_smash)
        end
        options
      end

      # Wrap action within nice text. Output resulting Hash if provided
      #
      # @param msg [String] message of action in progress
      # @yieldblock action to execute
      # @yieldreturn [Hash] result to output
      # @return [TrueClass]
      def run_action(msg)
        ui.info("#{msg}... ", :nonewline)
        begin
          result = yield
          ui.puts ui.color('complete!', :green, :bold)
          if(result.is_a?(Hash))
            ui.puts '---> Results:'
            result.each do |k,v|
              ui.puts "    #{ui.color("#{k}:", :bold)} #{v}"
            end
          end
        rescue => e
          ui.puts ui.color('error!', :red, :bold)
          ui.error "Reason - #{e}"
          raise
        end
        true
      end

    end

  end
end

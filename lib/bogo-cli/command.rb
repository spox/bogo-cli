require 'bogo-ui'
require 'bogo-config'
require 'bogo-cli'

module Bogo
  module Cli
    # Abstract command class
    class Command

      include Bogo::Memoization

      # @return [Hash] options
      attr_reader :options
      # @return [Array] cli arguments
      attr_reader :arguments
      # @return [Ui]
      attr_reader :ui

      # Build new command instance
      #
      # @return [self]
      def initialize(cli_opts, args)
        @options = cli_opts.to_hash.to_smash(:snake)
        @options.delete_if{|k,v| v.nil?}
        @arguments = args
        ui_args = Smash.new(
          :app_name => options.fetch(:app_name,
            self.class.name.split('::').first
          )
        ).merge(cli_opts.to_hash.to_smash).merge(opts)
        @ui = options.delete(:ui) || Ui.new(ui_args)
        load_config!
      end

      # Execute the command
      #
      # @return [TrueClass]
      def execute!
        raise NotImplementedError
      end

      protected

      # Provides top level options with command specific options
      # merged to provide custom overrides
      #
      # @return [Smash]
      def config
        options.to_smash.deep_merge(opts.to_smash)
      end

      # Command specific options
      #
      # @return [Smash]
      def opts
        Smash[
          options.fetch(
            Bogo::Utility.snake(
              self.class.name.split('::').last
            ),
            Hash.new
          ).map{|k,v|
            unless(v.nil?)
              [k,v]
            end
          }.compact
        ]
      end

      # Load configuration file and merge opts
      # on top of file values
      #
      # @return [Hash]
      def load_config!
        if(options[:config])
          config_inst = config_class.new(options[:config])
        elsif(self.class.const_defined?(:DEFAULT_CONFIGURATION_FILES))
          path = self.class.const_get(:DEFAULT_CONFIGURATION_FILES).detect do |check|
            full_check = File.expand_path(check)
            File.exists?(full_check)
          end
          config_inst = config_class.new(path) if path
        end
        new_opts = config_class.new(options)
        @options = new_opts.to_smash
        if(config_inst)
          merge_opts = Smash[options.to_smash.map{|k,v| [k,v] unless v.nil?}.compact]
          merge_opts.delete(:config)
          @options = config_inst.to_smash.deep_merge(merge_opts)
        end
        options
      end

      # @return [Class] config class
      def config_class
        Bogo::Config
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
          if(result)
            ui.puts '---> Results:'
            case result
            when Hash
              result.each do |k,v|
                ui.puts '    ' << ui.color("#{k}: ", :bold) << v
              end
            else
              ui.puts result
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

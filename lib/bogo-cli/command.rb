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
      # @return [Hash] default options
      attr_reader :defaults
      # @return [Array] cli arguments
      attr_reader :arguments
      # @return [Ui]
      attr_reader :ui

      # Build new command instance
      #
      # @return [self]
      def initialize(cli_opts, args)
        if(cli_opts.is_a?(Slop))
          process_cli_options(cli_opts)
        else
          @defaults = Smash.new
          @options = cli_opts.to_hash.to_smash(:snake)
          [@options, *@options.values].compact.each do |hsh|
            next unless hsh.is_a?(Hash)
            hsh.delete_if{|k,v| v.nil?}
          end
        end
        @arguments = validate_arguments!(args)
        load_config!
        ui_args = Smash.new(
          :app_name => options.fetch(:app_name,
            self.class.name.split('::').first
          )
        ).merge(config)
        @ui = options.delete(:ui) || Ui.new(ui_args)
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
          config_inst = Config.new(options[:config])
        elsif(self.class.const_defined?(:DEFAULT_CONFIGURATION_FILES))
          path = self.class.const_get(:DEFAULT_CONFIGURATION_FILES).detect do |check|
            full_check = File.expand_path(check)
            File.exists?(full_check)
          end
          config_inst = Config.new(path) if path
        end
        if(config_inst)
          options.delete(:config)
          defaults_inst = Smash[
            config_class.new(
              defaults.to_smash
            ).to_smash.find_all do |key, value|
              defaults.key?(key)
            end
          ]
          config_data = config_inst.data
          config_inst = Smash[
            config_inst.to_smash.find_all do |key, value|
              config_data.key?(key)
            end
          ]
          options_inst = Smash[
            config_class.new(
              options.to_smash
            ).to_smash.find_all do |key, value|
              options.key?(key)
            end
          ]
          @options = config_class.new(
            defaults_inst.to_smash.deep_merge(
              config_inst.to_smash.deep_merge(
                options_inst.to_smash
              )
            )
          ).to_smash
        else
          @options = config_class.new(
            defaults.to_smash.deep_merge(
              options.to_smash
            )
          ).to_smash
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

      # Process the given CLI options and isolate default values from
      # user provided values
      #
      # @param cli_opts [Slop]
      # @return [NilClass]
      def process_cli_options(cli_opts)
        unless(cli_opts.is_a?(Slop))
          raise TypeError.new "Expecting type `Slop` but received type `#{cli_opts.class}`"
        end
        @options = Smash.new
        @defaults = Smash.new
        cli_opts.each do |cli_opt|
          unless(cli_opt.value.nil?)
            opt_key = Bogo::Utility.snake(cli_opt.key)
            if(cli_opt.default?)
              @defaults[opt_key] = cli_opt.value
            else
              @options[opt_key] = cli_opt.value
            end
          end
        end
        nil
      end

      # Check for flags within argument list
      #
      # @param list [Array<String>]
      # @return [Array<String>]
      def validate_arguments!(list)
        chk_idx = list.find_index do |item|
          item.start_with?('-')
        end
        if(chk_idx)
          marker = list.find_index do |item|
            item == '--'
          end
          if(marker.nil? || chk_idx.to_i < marker)
            raise ArgumentError.new "Unknown CLI option provided `#{list[chk_idx]}`"
          end
        end
        list
      end

    end

  end
end

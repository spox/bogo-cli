require 'forwardable'
require 'optparse'
require 'ostruct'

module Bogo
  module Cli
    # Parser for CLI arguments
    class Parser
      # @return [Symbol] represent unset value
      UNSET = :__unset__

      class OptionValues
        extend Forwardable

        NONFORWARDABLE = [:is_a?, :respond_to?, :object_id, :inspect, :keys, :to_s, :[]=].freeze

        Smash.public_instance_methods.each do |ifunc|
          next if ifunc.to_s.start_with?("_") || NONFORWARDABLE.include?(ifunc)
          def_delegator :composite, ifunc
        end

        def initialize
          @defaults = Smash.new
          @sets = Smash.new
        end

        def []=(key, value)
          assign(key, value)
        end

        def assign(key, value)
          @sets[key] = value
          self
        end

        def set_default(key, value)
          @defaults[key] = value
          self
        end

        def keys
          @sets.keys | @defaults.keys
        end

        def default?(key)
          unless keys.include?(key)
            raise KeyError,
                  "Unknown option key '#{key}'"
          end
          !@sets.keys.include?(key)
        end

        def to_s
          "<OptionValues: #{composite.inspect}>"
        end

        def inspect
          "<OptionValues: #{@sets.inspect} | #{@defaults.inspect}>"
        end

        def is_a?(const)
          super || composite.is_a?(const)
        end

        def respond_to?(method)
          super || composite.respond_to?(method)
        end

        def composite
          Smash.new.tap do |c|
            keys.each do |k|
              c[k] = @sets.fetch(k, @defaults[k])
            end
          end
        end
      end

      # Modified option parser to include
      # subcommand information
      class OptionParser < ::OptionParser
        attr_accessor :subcommands

        def help
          v = super
          return v if Array(subcommands).empty?
          v += "\n" + "Available Commands:\n\n"
          Array(subcommands).each do |sc|
            v += summary_indent + sc.name.to_s + "\t" + sc.description.to_s + "\n"
          end
          v + "\n" + 'See `<command> --help` for more information on a specific command.'
        end
      end

      class Command
        # @return [Array<Command>] list of subcommands
        attr_reader :commands
        # @return [String] name of command
        attr_reader :name
        # @return [Array<Flag>] flags for command
        attr_reader :flags
        # @return [Proc] callable to be executed
        attr_reader :callable
        # @return [OpenStruct] flag option values
        attr_reader :options
        # @return [OptionParser] command parser
        attr_reader :parser

        # Create a new command
        #
        # @param name [String, Symbol] name of command
        # @return [Command]
        def initialize(name)
          @name = name.to_sym
          @commands = []
          @flags = []
          @callable = nil
          @options = OptionValues.new
        end

        # Add a new flag
        #
        # @param short [String, Symbol] short flag
        # @param long [String, Symbol] long flag
        # @param description [String] description of flag
        # @param default [String] default flag value
        def on(short, long, description=UNSET, opts={}, &block)
          if short.to_s.size > 1
            if description == UNSET
              description = long
              long = short
              short = nil
            elsif description.is_a?(Hash)
              opts = description
              description = long
              long = short
              short = nil
            end
          end
          Flag.new(
            short_name: short,
            long_name: long,
            description: description,
            default: opts[:default],
            callable: block,
          ).tap do |f|
            @flags << f
          end
        end

        # Add a new command
        #
        # @param name [String, Symbol] name of command
        def command(name, &block)
          Command.new(name).load(&block).tap do |c|
            @commands << c
          end
        end

        # @return [String] description of command
        def description(v=UNSET)
          @description = v unless v == UNSET
          @description
        end

        # Register callable for command
        def run(&block)
          @callable = block
        end

        # Load a command configuration block
        def load(&block)
          instance_exec(&block)
          self
        end

        # @return [String] help output
        def help
          parser.help
        end

        # Parse the arguments
        #
        # @param arguments [Array<String>] CLI arguments
        # @return [OpenStruct, Array<String>]
        def parse(arguments)
          raise "Must call #generate before #parse" if
            parser.nil?
          flags.each do |f|
            next if f.default.nil?
            options.set_default(f.option_name, f.default)
          end
          init = OpenStruct.new
          parser.parse!(arguments, into: init)
          init.each_pair do |k, v|
            options.assign(k, v)
          end
          [options, arguments]
        end

        # Generate command parsers
        #
        # @param parents [Array<String,Symbol>] ancestors of command
        # @return [Hash<string,OptParser>]
        def generate(parents=[], add_help: true)
          Hash.new.tap { |cmds|
            @parser = OptionParser.new
            full_name = parents + [name]
            parser.program_name = full_name.join(' ')
            parser.banner = description unless
              description == UNSET
            if add_help
              parser.on('-h', '--help', "Display help information") do
                $stderr.puts parser.help
                exit
              end
            end
            flags.each { |f|
              if !f.boolean? && f.long_name.end_with?('=')
                short = "-#{f.short_name}" if f.short_name
                long = "--#{f.long_name[0, f.long_name.size - 1]} VALUE"
              else
                short = "-#{f.short_name}" if f.short_name
                long = "--#{f.long_name}"
              end
              parser.on(short, long, f.description, &f.callable)
            }

            commands.map { |c|
              c.generate(full_name, add_help: add_help)
            }.inject(cmds) { |memo, list|
              memo.merge!(list)
            }

            parser.subcommands = commands

            cmds[full_name.join(' ')] = self
          }
        end

        def to_hash
          options.to_h
        end
      end

      class Flag
        # @return [String] short flag
        attr_reader :short_name
        # @return [String] long flag
        attr_reader :long_name
        # @return [String] default value
        attr_reader :default
        # @return [String] flag description
        attr_reader :description
        # @return [Proc] block to execute on flag called
        attr_reader :callable

        # Create a new flag
        #
        # @param short_name [String, Symbol] Single character flag
        # @param long_name [String, Symbol] Full flag name
        # @param description [String] Description of flag
        # @param default [Object] Default value for flag
        # @return Flag
        def initialize(long_name:,
          short_name: nil,
          description: nil,
          default: nil,
          callable: nil
        )
          if short_name
            short_name = short_name.to_s
            short_name = short_name[1, short_name.size] if
              short_name.start_with?('-')
            raise ArgumentError,
              "Flag short name must be single character (flag: #{short_name})" if
              short_name.size > 1
          end
          @short_name = short_name
          @long_name = long_name.to_s.sub(/^-+/, '').gsub('_', '-')
          @description = description
          @default = default
          @callable = callable
        end

        # @return [Symbol] option compatible name
        def option_name
          long_name.split('=').first.gsub('-', '_').to_sym
        end

        # @return [Boolean] flag is boolean value
        def boolean?
          !long_name.include?('=')
        end
      end

      # @return [Boolean] generate help content
      attr_accessor :generate_help

      # Parse a command setup block, process arguments
      # and execute command if match found
      #
      # @param help [Boolean] generate help content
      # @return [Object] result
      def self.parse(help: true, &block)
        parser = self.new
        parser.generate_help = !!help
        parser.load(&block)
        parser.execute
      end

      # Create a new parser
      #
      # @param name [String, Symbol] name of root command
      # @return [Parser]
      def initialize(name: nil)
        name = self.class.root_name unless name
        @root = Command.new(name)
      end

      # Add a new command
      #
      # @param name [String, Symbol] name of command
      def command(name, &block)
        @root.command(name, &block)
      end

      # Add a new flag
      #
      # @param short [String, Symbol] short flag
      # @param long [String, Symbol] long flag
      # @param description [String] description of flag
      # @param default [String] default flag value
      def on(short, long, description, **options, &block)
        @root.on(short, long, description, options, &block)
      end

      # Register callable for command
      def run(&block)
        @root.run(&block)
      end

      # Load a command configuration block
      def load(&block)
        @root.load(&block)
      end

      # Generate all parsers
      #
      # @return [Hash<String,Hash<Parser,Command>>]
      def generate
        @root.generate(add_help: generate_help)
      end

      # Execute command based on CLI arguments
      def execute
        cmds = @root.generate
        base_args = arguments
        line = base_args.join(' ')
        cmd_key = cmds.keys.find_all { |k|
          line.start_with?(k)
        }.sort_by(&:size).last
        if cmd_key.nil?
          return cmds[@root.name].parser
        end
        base_args = base_args.slice(cmd_key.split(' ').size, base_args.size)
        a = cmds[cmd_key].parse(base_args)
        return cmds[cmd_key] unless cmds[cmd_key].callable
        cmds[cmd_key].callable.call(*a)
        exit 0
      end

      private

      # @return [Array<String>]
      def arguments
        [self.class.root_name] + ARGV
      end

      def self.root_name
        File.basename($0)
      end
    end
  end
end

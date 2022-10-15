require_relative '../spec'

require 'stringio'

describe Bogo::Cli::Command do

  before do
    @output = StringIO.new('')
    @command = Bogo::Cli::Command.new(
      Smash.new(
        :ui => Bogo::Ui.new(
          :output_to => @output,
          :app_name => 'CommandTest',
          :colors => false
        ),
        :config => File.join(File.dirname(__FILE__), 'config', 'test.json'),
        :null_value => nil
      ),
      ['arg1', 'arg2']
    )
  end

  describe 'Abstract command' do

    it 'should have configuration available via #options' do
      _(@command.options.get(:test)).must_equal Smash.new(:name => 'fubar', :port => 80)
    end

    it 'should have class namespaced configuration available via #opts' do
      _(@command.send(:opts)).must_equal Smash.new(:namespaced => true, :override => 'yes', :null_value => 'set')
    end

    it 'should have options merged with namespaced configuration via #config' do
      _(@command.send(:options)[:override]).must_equal 'no'
      _(@command.send(:config)[:override]).must_equal 'yes'
      _(@command.send(:config)[:item]).must_equal 'thing'
    end

    it 'should remove nil value options' do
      _(@command.send(:options).has_key?(:null_value)).must_equal false
    end

    it 'should properly merge namespaced item with nil root item' do
      _(@command.send(:config)[:null_value]).must_equal 'set'
    end

    it 'should have an abstract #execute! method for subclassing' do
      _(->{ @command.execute! }).must_raise NotImplementedError
    end

    describe 'Output wrapper' do

      it 'should wrap action with given text' do
        @command.send(:run_action, 'Test action'){ nil }
        @output.rewind
        _(@output.read).must_equal "[CommandTest]: Test action... complete!\n"
      end

      it 'should output enumerated result if Hash' do
        @command.send(:run_action, 'Test action'){ Smash.new(:result => 'ohai!') }
        @output.rewind
        _(@output.read).must_equal "[CommandTest]: Test action... complete!\n---> Results:\n    result: ohai!\n"
      end

      it 'should output direct result if truthy non-Hash' do
        @command.send(:run_action, 'Test action'){ 'ohai!' }
        @output.rewind
        _(@output.read).must_equal "[CommandTest]: Test action... complete!\n---> Results:\nohai!\n"
      end

      it 'should not output result if falsey' do
        @command.send(:run_action, 'Test action'){ false }
        @output.rewind
        _(@output.read).must_equal "[CommandTest]: Test action... complete!\n"
      end

    end

    describe 'CLI option merging' do

      before do
        @cli = Bogo::Cli::Parser.parse do
          on :n, :null_value=, 'Option', :default => 'ohai'
          on :c, :config=, 'Option'
          on :z, :cli_defaulter=, 'Option', :default => 'CLI DEFAULT'
        end
      end

      it 'should provide the default option value' do
        _(Bogo::Cli::Command.new(@cli, []).send(:config)[:null_value]).must_equal 'ohai'
      end

      it 'should override the default value' do
        @cli.options[:config] = File.join(File.dirname(__FILE__), 'config', 'test.json')
        _(Bogo::Cli::Command.new(@cli, []).send(:config)[:null_value]).must_equal 'set'
      end

      it 'should deep merge hash values' do
        command_class = Class.new(Bogo::Cli::Command)
        command_class.class_eval do
          def self.name
            'MyCommand'
          end
          def config_class
            spec_config_class = Class.new(Bogo::Config)
            spec_config_class.class_eval do
              attribute :test, Hash, :coerce => lambda{|x| Hash[*x.split(':')] }
            end
            spec_config_class
          end
        end
        command = command_class.new({
          :test => 'new:item',
          :config => File.join(File.dirname(__FILE__), 'config', 'test.json')
        }, {})
        config = command.send(:config)
        _(config[:test][:new]).must_equal 'item'
        _(config[:test][:name]).must_equal 'fubar'
      end

      it 'should not clobber configuration file values' do
        command_class = Class.new(Bogo::Cli::Command)
        command_class.class_eval do
          def self.name
            'MyCommand'
          end
          def config_class
            spec_config_class = Class.new(Bogo::Config)
            spec_config_class.class_eval do
              attribute :item, String, :default => 'DEFAULT'
            end
            spec_config_class
          end
        end
        command = command_class.new({}, [])
        config = command.send(:config)
        _(config[:item]).must_equal 'DEFAULT'
        command = command_class.new({
          :config => File.join(File.dirname(__FILE__), 'config', 'test.json')
        }, [])
        config = command.send(:config)
        _(config[:item]).must_equal 'thing'
        command = command_class.new({
          :item => 'CUSTOM',
          :config => File.join(File.dirname(__FILE__), 'config', 'test.json')
        }, [])
        config = command.send(:config)
        _(config[:item]).must_equal 'CUSTOM'
      end

      it 'should use CLI default over configuration default' do
        command_class = Class.new(Bogo::Cli::Command)
        command_class.class_eval do
          def self.name
            'MyCommand'
          end
          def config_class
            spec_config_class = Class.new(Bogo::Config)
            spec_config_class.class_eval do
              attribute :cli_defaulter, String, :default => 'CONFIG DEFAULT'
            end
            spec_config_class
          end
        end
        command = command_class.new(@cli, [])
        config = command.send(:config)
        _(config[:cli_defaulter]).must_equal 'CLI DEFAULT'
        @cli.options[:config] = File.join(File.dirname(__FILE__), 'config', 'test.json')
        command = command_class.new(@cli, [])
        config = command.send(:config)
        _(config[:cli_defaulter]).must_equal 'CLI DEFAULT'
        @cli.options[:cli_defaulter] = 'CUSTOM'
        command = command_class.new(@cli, [])
        config = command.send(:config)
        _(config[:cli_defaulter]).must_equal 'CUSTOM'
      end

    end

    describe 'CLI argument processing' do

      it 'should accept list of acceptable strings' do
        _(Bogo::Cli::Command.new({}, ['arg1', 'arg2'])).wont_be_nil
      end

      it 'should error when provided flag in argument list' do
        _(->{ Bogo::Cli::Command.new({}, ['arg1', '-x', 'arg2']) }).must_raise ArgumentError
      end

      it 'should error when provided flag in argument list before double dash' do
        _(->{ Bogo::Cli::Command.new({}, ['arg1', '-x', '--', 'arg2']) }).must_raise ArgumentError
      end

      it 'should allow flag in argument list if after double dash' do
        _(Bogo::Cli::Command.new({}, ['arg1', '--', '-x', 'arg2'])).wont_be_nil
      end

      it 'should include bad argument value within exception message' do
        exception = nil
        begin
          Bogo::Cli::Command.new({}, ['arg1', '-x', 'arg2'])
        rescue => exception
        end
        _(exception.message).must_include '-x'
      end

    end

    describe 'Configuration file loading' do

      it 'should load configuration file without error' do
        cmd = Bogo::Cli::Command.new({:config => File.join(File.dirname(__FILE__), 'config', 'test.json')}, [])
        _(cmd).must_be_kind_of Bogo::Cli::Command
      end

      it 'should produce custom error when loading fails' do
        _(->{
          Bogo::Cli::Command.new({:config => File.join(File.dirname(__FILE__), 'config', 'fail.json')}, [])
        }).must_raise Bogo::Config::FileLoadError
      end

    end

  end

end

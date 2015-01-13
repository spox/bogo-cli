require 'stringio'
require 'minitest/autorun'

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
        :config => File.join(File.dirname(__FILE__), 'config', 'test.json')
      ),
      ['arg1', 'arg2']
    )
  end

  describe 'Abstract command' do

    it 'should have configuration available via #options' do
      @command.options.get(:test).must_equal Smash.new(:name => 'fubar', :port => 80)
    end

    it 'should have class namespaced configuration available via #opts' do
      @command.send(:opts).must_equal Smash.new(:namespaced => true)
    end

    it 'should have an abstract #execute! method for subclassing' do
      ->{ @command.execute! }.must_raise NotImplementedError
    end

    describe 'Output wrapper' do

      it 'should wrap action with given text' do
        @command.send(:run_action, 'Test action'){ nil }
        @output.rewind
        @output.read.must_equal "[CommandTest]: Test action... complete!\n"
      end

      it 'should output enumerated result if Hash' do
        @command.send(:run_action, 'Test action'){ Smash.new(:result => 'ohai!') }
        @output.rewind
        @output.read.must_equal "[CommandTest]: Test action... complete!\n---> Results:\n    result: ohai!\n"
      end

      it 'should output direct result if truthy non-Hash' do
        @command.send(:run_action, 'Test action'){ 'ohai!' }
        @output.rewind
        @output.read.must_equal "[CommandTest]: Test action... complete!\n---> Results:\nohai!\n"
      end

      it 'should not output result if falsey' do
        @command.send(:run_action, 'Test action'){ false }
        @output.rewind
        @output.read.must_equal "[CommandTest]: Test action... complete!\n"
      end

    end
  end

end
# frozen_string_literal: true

require_relative '../../../spec_helper_legacy'

describe LegacyFacter::Core::Execution::Base do
  describe '#with_env' do
    it "should execute the caller's block with the specified env vars" do
      test_env = { 'LANG' => 'C', 'LC_ALL' => 'C', 'FOO' => 'BAR' }
      subject.with_env test_env do
        test_env.keys.each do |key|
          expect(ENV[key]).to eq test_env[key]
        end
      end
    end

    it 'should restore pre-existing environment variables to their previous values' do
      orig_env = {}
      new_env = {}
      # an arbitrary sentinel value to use to temporarily set the environment vars to
      sentinel_value = 'Abracadabra'

      # grab some values from the existing ENV (arbitrarily choosing 3 here)
      ENV.keys.first(3).each do |key|
        # save the original values so that we can test against them later
        orig_env[key] = ENV[key]
        # create bogus temp values for the chosen keys
        new_env[key] = sentinel_value
      end

      # verify that, during the 'with_env', the new values are used
      subject.with_env new_env do
        orig_env.keys.each do |key|
          expect(ENV[key]).to eq new_env[key]
        end
      end

      # verify that, after the 'with_env', the old values are restored
      orig_env.keys.each do |key|
        expect(ENV[key]).to eq orig_env[key]
      end
    end

    it "should not be affected by a 'return' statement in the yield block" do
      @sentinel_var = :resolution_test_foo.to_s

      # the intent of this test case is to test a yield block that contains a return statement.  However, it's illegal
      # to use a return statement outside of a method, so we need to create one here to give scope to the 'return'
      def handy_method
        ENV[@sentinel_var] = 'foo'
        new_env = { @sentinel_var => 'bar' }

        subject.with_env new_env do
          expect(ENV[@sentinel_var]).to eq 'bar'
          return
        end
      end

      handy_method

      expect(ENV[@sentinel_var]).to eq 'foo'
    end
  end

  describe '#execute' do
    it 'switches LANG and LC_ALL to C when executing the command' do
      expect(subject).to receive(:with_env).with('LC_ALL' => 'C', 'LANG' => 'C')
      subject.execute('foo')
    end

    it 'expands the command before running it' do
      allow(subject).to receive(:`).and_return ''
      expect(subject).to receive(:expand_command).with('foo').and_return '/bin/foo'
      expect(Kernel).to receive(:exec).with('/bin/foo').and_return('')
      subject.execute('foo')
    end

    describe 'and the command is not present' do
      it 'raises an error when the :on_fail behavior is :raise' do
        expect(subject).to receive(:expand_command).with('foo').and_return(nil)
        expect { subject.execute('foo') }.to raise_error(LegacyFacter::Core::Execution::ExecutionFailure)
      end

      it 'returns the given value when :on_fail is set to a value' do
        expect(subject).to receive(:expand_command).with('foo').and_return(nil)
        expect(subject.execute('foo', on_fail: nil)).to be_nil
      end
    end

    describe 'when command execution fails' do
      before do
        expect(Kernel).to receive(:exec).with('/bin/foo').and_raise('kaboom!')
        expect(subject).to receive(:expand_command).with('foo').and_return('/bin/foo')
      end

      it 'raises an error when the :on_fail behavior is :raise' do
        expect { subject.execute('foo') }.to raise_error(LegacyFacter::Core::Execution::ExecutionFailure)
      end

      it 'returns the given value when :on_fail is set to a value' do
        expect(subject.execute('foo', on_fail: nil)).to be_nil
      end
    end

    it 'launches a thread to wait on children if the command was interrupted' do
      expect(Kernel).to receive(:exec).with('/bin/foo').and_raise('kaboom!')
      expect(subject).to receive(:expand_command).with('foo').and_return '/bin/foo'

      allow(LegacyFacter).to receive(:warn)
      expect(Thread).to receive(:new).and_yield
      expect(Process).to receive(:waitall).once

      subject.execute('foo', on_fail: nil)
    end

    it 'returns the output of the command' do
      expect(Kernel).to receive(:exec).with('/bin/foo').and_return('hi')
      expect(subject).to receive(:expand_command).with('foo').and_return '/bin/foo'

      expect(subject.execute('foo')).to eq 'hi'
    end

    it 'strips off trailing newlines' do
      expect(Kernel).to receive(:exec).with('/bin/foo').and_return("hi\n")
      expect(subject).to receive(:expand_command).with('foo').and_return '/bin/foo'

      expect(subject.execute('foo')).to eq 'hi'
    end
  end
end

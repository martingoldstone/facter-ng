# frozen_string_literal: true

describe 'Fedora Kernelmajversion' do
  context '#call_the_resolver' do
    it 'returns a fact' do
      value = '4.19'

      expected_fact = double(Facter::ResolvedFact, name: 'kernelmajversion', value: value)
      allow(Facter::Resolvers::Uname).to receive(:resolve).with(:kernelrelease).and_return(value)
      allow(Facter::ResolvedFact).to receive(:new).with('kernelmajversion', value).and_return(expected_fact)

      fact = Facter::Fedora::Kernelmajversion.new
      expect(fact.call_the_resolver).to eq(expected_fact)
    end
  end
  describe '#call_the_resolver' do
    context 'when full version is separated by . delimeter' do
      let(:value) { '4.15' }

      include_examples 'kernelmajversion fact expectation'
    end

    context 'when full version does not have a . delimeter' do
      let(:value) { '4test' }

      include_examples 'kernelmajversion fact expectation'
    end
  end
end

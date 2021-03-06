require 'spec_helper'

RSpec.describe Qo::Branches::ErrorBranch do
  let(:destructure)  { false }

  let(:branch) {
    Qo::Branches::ErrorBranch.new(destructure: destructure)
  }

  describe '.initialize' do
    it 'can be initialized' do
      expect(branch).to be_a(Qo::Branches::ErrorBranch)
    end
  end

  describe '#create_matcher' do
    let(:match_condition) { Any }
    let(:match_fn) { Qo::IDENTITY }
    let(:matcher) { branch.create_matcher(match_condition, &match_fn) }

    it 'can create a matcher' do
      expect(matcher).to be_a(Proc)
    end

    it 'will match anything and return true on an Any condition with no function' do
      expect(matcher.call([:err, nil])).to eq([true, nil])
      expect(matcher.call([:err, 42])).to eq([true, 42])
      expect(matcher.call([:err, 'String'])).to eq([true, 'String'])
      expect(matcher.call([:err, { hash: 'stuff' }])).to eq([true, { hash: 'stuff' }])
    end

    context 'With a Qo condition' do
      let(:match_condition) { Qo.and(Integer, 1..10, :even?) }

      it 'matches with a number matching the condition' do
        expect(matcher.call([:err, 2])).to eq([true, 2])
      end

      it 'will not match if the condition is not met' do
        expect(matcher.call([:err, 3])).to eq([false, nil])
      end
    end

    context 'With destructuring' do
      let(:destructure) { true }
      let(:person) { Person.new('Foo', 42) }
      let(:match_fn) { proc { |name, age| Person.new(name, age + 1) } }

      it 'can be used to give someone a birthday' do
        status, result = matcher.call([:err, person])

        expect(status).to eq(true)
        expect(result.age).to eq(43)
      end
    end
  end
end

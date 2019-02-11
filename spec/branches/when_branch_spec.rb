require 'spec_helper'

RSpec.describe Qo::Branches::WhenBranch do
  let(:destructure)  { false }

  let(:branch) {
    Qo::Branches::WhenBranch.new(destructure: destructure)
  }

  describe '.initialize' do
    it 'can be initialized' do
      expect(branch).to be_a(Qo::Branches::WhenBranch)
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
      expect(matcher.call(nil)).to eq([true, nil])
      expect(matcher.call(42)).to eq([true, 42])
      expect(matcher.call('String')).to eq([true, 'String'])
      expect(matcher.call({ hash: 'stuff' })).to eq([true, { hash: 'stuff' }])
    end

    context 'With a Qo condition' do
      let(:match_condition) { Qo.and(Integer, 1..10, :even?) }

      it 'matches with a number matching the condition' do
        expect(matcher.call(2)).to eq([true, 2])
      end

      it 'will not match if the condition is not met' do
        expect(matcher.call(3)).to eq([false, nil])
      end
    end

    context 'With destructuring' do
      let(:destructure) { true }
      let(:person) { Person.new('Foo', 42) }
      let(:match_fn) { proc { |name, age| Person.new(name, age + 1) } }

      it 'can be used to give someone a birthday' do
        status, result = matcher.call(person)

        expect(status).to eq(true)
        expect(result.age).to eq(43)
      end
    end
  end
end

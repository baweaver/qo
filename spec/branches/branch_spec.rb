require 'spec_helper'

RSpec.describe Qo::Branches::Branch do
  let(:name)         { 'when' }
  let(:precondition) { Any }
  let(:extractor)    { Qo::IDENTITY }
  let(:destructure)  { false }
  let(:default)      { false }

  let(:branch) {
    Qo::Branches::Branch.new(
      name:         name,
      precondition: precondition,
      extractor:    extractor,
      destructure:  destructure,
      default:      default
    )
  }

  context 'ordered' do
    it do
      collaborator_1 = ->(x) { true }
      collaborator_2 = ->(x) {}

      expect(collaborator_1).to receive(:===).and_return(true).ordered
      expect(collaborator_2).to receive(:call).ordered

      subject = proc do |x|
        if collaborator_1 === x
          collaborator_2.call(x)
        end
      end

      subject.call()
    end
  end

  context 'order of execution' do
    let(:callback) { Qo::IDENTITY }
    let(:condition) { Any }

    let(:matcher) { branch.create_matcher(condition, &callback) }

    let(:precondition) { ->(_) {} }
    let(:extractor) { ->(_) {} }

    it 'precondition -> extractor -> condition' do
      expect(precondition).to receive(:===).and_return(true).ordered
      expect(extractor).to receive(:call).ordered
      expect(condition).to receive(:===).ordered

      matcher.call(42)
    end
  end

  describe '.initialize' do
    it 'can be initialized' do
      expect(branch).to be_a(Qo::Branches::Branch)
    end
  end

  describe '#default?' do
    it 'responds false whenever it is not a default branch' do
      expect(branch.default?).to eq(false)
    end

    context 'When default is set to true' do
      let(:default) { true }

      it 'responds true' do
        expect(branch.default?).to eq(true)
      end
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

    context 'With a precondition' do
      let(:precondition) { Integer }

      it 'will try and match the precondition before anything else' do
        expect(matcher.call(1)).to eq([true, 1])
      end

      it 'will not match if the precondition fails' do
        expect(matcher.call('s')).to eq([false, nil])
      end
    end

    context 'With an extractor' do
      let(:extractor) { :last }
      let(:precondition) { Qo[:ok, Any] }

      it 'can be used to extract a value from a tuple before yielding to the match function' do
        expect(matcher.call([:ok, 1])).to eq([true, 1])
      end
    end
  end

  describe '.create' do
    let(:name) { 'some' }
    let(:preconditions) { Some }
    let(:extractor) { :value }

    let(:new_matcher) {
      Qo::Branches::Branch.create(
        name:         name,
        precondition: precondition,
        extractor:    extractor,
        destructure:  destructure,
        default:      default
      )
    }

    let(:match_condition) { Any }
    let(:match_fn) { Qo::IDENTITY }
    let(:matcher) { new_matcher.new.create_matcher(match_condition, &match_fn) }

    it 'can be used to create a custom matcher' do
      expect(matcher.call(Some[1])).to eq([true, 1])
    end
  end
end

require 'spec_helper'

RSpec.describe Qo::Destructurers::Destructurer do
  let(:should_destructure) { true }
  let(:function) { -> itself { itself } }

  let(:destructurer) {
    Qo::Destructurers::Destructurer.new(
      should_destructure: should_destructure, &function
    )
  }

  describe '.initialize' do
    it 'initializes' do
      expect(destructurer).to be_a(Qo::Destructurers::Destructurer)
    end
  end

  describe '#destructure?' do
    it 'returns true when the class has destructuring set to run' do
      expect(destructurer.destructure?).to eq(true)
    end

    context 'When destructuring is turned off' do
      let(:should_destructure) { false }

      it 'returns false' do
        expect(destructurer.destructure?).to eq(false)
      end
    end
  end

  describe '#argument_names' do
    it 'extracts the argument names from a function' do
      expect(destructurer.argument_names).to eq([:itself])
    end
  end

  describe '#destructure_values' do
    let(:destructured_values) { destructurer.destructure_values(target) }

    context 'With an Object' do
      let(:target) { Person.new('Foo', 42) }
      let(:function) { -> name, age { } }

      it 'destructures values from the object' do
        expect(destructured_values).to eq(['Foo', 42])
      end

      context 'When presented with a method the object does not respond to' do
        let(:function) { -> not_existant {} }

        it 'returns `false` for that parameter' do
          expect(destructured_values).to eq([false])
        end
      end
    end

    context 'With a Hash' do
      let(:target) { { name: 'Foo', age: 42 } }
      let(:function) { -> name, age { } }

      it 'destructures values from the object' do
        expect(destructured_values).to eq(['Foo', 42])
      end

      context 'When presented with a method the object does not respond to' do
        let(:function) { -> not_existant {} }

        it 'returns the respective `Hash#default_value` for that parameter' do
          expect(destructured_values).to eq([nil])
        end
      end
    end
  end

  describe '#call' do
    let(:target) { Person.new('Foo', 42) }

    # Ruby 2.4+ won't 'splat' lambda args, which is quite pesky
    let(:function) { proc { |name, age| Person.new(name, age + 1) } }

    let(:result) { destructurer.call(target) }

    it 'calls the function with the destructured values' do
      expect(result.age).to eq(43)
    end
  end
end

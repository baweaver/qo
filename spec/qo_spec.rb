require "spec_helper"

class Person
  attr_reader :name

  def initialize(name, age)
    @name = name
    @age = age
  end

  def adult?
    @age > 17
  end

  def cool?
    @name.include?('Rob')
  end

  def to_h
    {name: @name, age: @age}
  end
end

people = [
  Person.new('Robert', 22),
  Person.new('Roberta', 22),
  Person.new('Foo', 42),
  Person.new('Bar', 17)
]

RSpec.describe Qo do
  let(:people) do
    [
      Person.new('Robert', 22),
      Person.new('Roberta', 22),
      Person.new('Foo', 42),
      Person.new('Bar', 17),
    ]
  end

  # `and` and `[]` are the same, one's just "nicer" to write
  describe '#and' do
    describe 'Array matchers' do
      let(:matched_array) { ['Robert', 22] }

      context 'With an Array matched against an Array' do
        it 'checks if the array matches positionally' do
          expect(Qo['Robert', 22] === matched_array).to eq(true)
        end

        it 'can utilize triple equals for regex' do
          expect(Qo[/Rob/, 22] === matched_array).to eq(true)
        end

        it 'can recognize wildcards' do
          expect(Qo[/Rob/, :*] === matched_array).to eq(true)
        end

        # These are entirely to give people suitably fun ideas of what to use
        # this with. They do provide some usefulness to testing, but that's not
        # the primary purpose
        context 'With other Ruby language features' do
          context 'With a simple collection' do
            let(:simple_collection) {
              [
                ['Robert', 22],
                ['Roberta', 22],
                ['Foo', 42],
                ['Bar', 18]
              ]
            }

            let(:query) { Qo[:*, 18..25] }

            it 'can be used with #select' do
              expect(
                simple_collection.select(&query)
              ).to eq([
                ['Robert', 22], ['Roberta', 22], ['Bar', 18]
              ])
            end

            it 'can be used with #all?, #any?, #none?, and #one?' do
              expect(simple_collection.all?(&query)).to eq(false)
              expect(simple_collection.any?(&query)).to eq(true)
              expect(simple_collection.none?(&query)).to eq(false)
              expect(simple_collection.one?(&query)).to eq(false)
            end

            it 'can be used with #find' do
              expect(simple_collection.find(&query)).to eq(['Robert', 22])
            end
          end
        end
      end

      context 'With an Array matched against an Object' do
        it 'can query against boolean attributes' do
          expect(
            people.select(&Qo[:adult?, :cool?]).map(&:name)
          ).to eq(
            %w(Robert Roberta)
          )
        end
      end
    end

    describe 'Hash matchers' do
      let(:matched_hash) { {name: 'Foo', age: 42} }

      it 'can match a hash to a hash' do
        expect(Qo[name: /^F/, age: :*] === matched_hash).to eq(true)
      end

      it 'can find matching hashes in an array' do
        expect(people.map(&:to_h).select(&Qo[name: /Rob/])).to eq([{
          name: "Robert", age: 22
        }, {
          name: "Roberta", age: 22
        }])
      end

      it 'works on objects too' do
        expect(people.select(&Qo[name: /Rob/]).map(&:name)).to eq(%w(Robert Roberta))
      end
    end
  end

  describe '#or' do
    it 'can be used to pretend we have nice Rails features' do
      expect([nil, '', 'Boo'].reject(&Qo.or(:nil?, :empty?))).to eq(['Boo'])
    end
  end

  describe '#not' do
    it 'can be used because we know someone is going to ask for it' do
      expect(
        people.select(&Qo.not(name: /Rob/)).map(&:name)
      ).to eq(%w(Foo Bar))
    end
  end
end

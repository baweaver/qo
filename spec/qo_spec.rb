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

        it 'can be used for select with triple equals respondant values' do
          expect(
            ['foo', 'bar', 'foobar'].select(&Qo[/foo/])
          ).to eq(
            ["foo", "foobar"]
          )
        end

        # I know this case is slightly confounded, but it does enable quite a bit
        # of fun with case statements later.
        it 'can be used for select with callable methods' do
          expect(
            [1,2,3].select(&Qo[:even?])
          ).to eq(
            [2]
          )
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

  # Test the inner workings we don't want to expose. The interface for Qo should stay the same, I
  # just _really_ don't want developers relying on internal behavior I may change over the next few
  # months.
  describe 'Private API' do
    let(:array_matchers) { [] }
    let(:keyword_matchers) { {} }

    let(:qo_matcher) { Qo::Matcher.new('and', *array_matchers, **keyword_matchers) }

    let(:method_name) { :nil? }
    let(:method_args) { [] }

    let(:result) { qo_matcher.send(method_name, *method_args) }

    describe '#case_match' do
      let(:method_name) { :case_match }
      let(:method_args) { ['Foo', /^F/] }

      it 'basically wraps `===`' do
        expect(result).to eq(true)
      end
    end

    describe '#wildcard_match' do
      let(:method_name) { :wildcard_match }
      let(:method_args) { [:*] }

      it 'can match against a wildcard' do
        expect(result).to eq(true)
      end

      context 'When provided a value not matching the wildcard' do
        let(:method_args) { [nil] }

        it 'will not match' do
          expect(result).to eq(false)
        end
      end
    end

    describe '#method_send' do
      let(:method_name) { :method_send }
      let(:method_args) { [1, :odd?] }

      it 'will return the result of sending a method' do
        expect(result).to eq(true)
      end

      context 'When the target does not respond to the matcher' do
        let(:method_args) { [1, :i_do_not_exist] }

        it 'returns false' do
          expect(result).to eq(false)
        end
      end

      context 'When the matcher does not respond to to_sym' do
        let(:method_args) { [1, /i don't symbolize well/] }

        it 'returns false' do
          expect(result).to eq(false)
        end
      end
    end

    describe '#method_matches?' do
      let(:method_name) { :method_matches? }
      let(:method_args) { [1, :succ] }

      it 'just wraps #method_send with a boolean coercion' do
        expect(result).to eq(true)
      end
    end

    describe '#match_with' do
      let(:method_name) { :match_with }
      let(:method_args) { [[1,2,3], :even?.to_proc] }

      it 'wraps the collection match' do
        expect(result).to eq(false)
      end
    end

    describe 'Matcher functions' do
      let(:matcher_fn) { result }
      let(:match_result) { matcher_fn[*matcher_args] }

      describe '#array_against_array_matcher' do
        let(:method_name) { :array_against_array_matcher }
        let(:method_args) { [1] }
        let(:matcher_args) { [Integer, 1] }

        it 'generates a function to match an array against matchers at the same index' do
          expect(match_result).to eq(true)
        end

        context 'When given a wildcard' do
          let(:matcher_args) { [:*, 1] }

          it 'will always match' do
            expect(match_result).to eq(true)
          end
        end
      end

      describe '#array_against_object_matcher' do
        let(:method_name) { :array_against_object_matcher }
        let(:method_args) { [1] }
        let(:matcher_args) { [Integer] }

        it 'generates a function to match an array against a collection of matchers' do
          expect(match_result).to eq(true)
        end

        context 'When given a wildcard' do
          let(:matcher_args) { [:*] }

          it 'will always match' do
            expect(match_result).to eq(true)
          end
        end

        context 'When given a predicate method' do
          let(:matcher_args) { [:even?] }

          it 'will call that method on the target' do
            expect(match_result).to eq(false)
          end
        end
      end

      describe '#hash_against_hash_matcher' do
        # Don't splat a hash
        let(:result) { qo_matcher.send(method_name, method_args) }

        let(:method_name) { :hash_against_hash_matcher }
        let(:method_args) { {name: 'Foobar'} }
        let(:matcher_args) { [:name, /Foo/] }

        it 'generates a function to match a hash pair against another hash' do
          expect(match_result).to eq(true)
        end

        context 'When given a wildcard' do
          let(:matcher_args) { [:name, :*] }

          it 'will always match' do
            expect(match_result).to eq(true)
          end
        end
      end

      describe '#hash_against_object_matcher' do
        let(:method_name) { :hash_against_object_matcher }
        let(:method_args) { [1] }
        let(:matcher_args) { [:to_s, '1'] }

        it 'generates a function to match a hash pair against an object using the key as a method and a value as a matcher' do
          expect(match_result).to eq(true)
        end

        context 'When given a wildcard' do
          let(:matcher_args) { [:to_s, :*] }

          it 'will always match' do
            expect(match_result).to eq(true)
          end
        end
      end
    end
  end
end

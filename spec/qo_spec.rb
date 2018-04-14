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

RSpec.describe Qo do
  let(:people) do
    [
      Person.new('Robert', 22),
      Person.new('Roberta', 22),
      Person.new('Foo', 42),
      Person.new('Bar', 17),
    ]
  end

  let(:people_arrays) do
    [
      ['Robert', 22],
      ['Roberta', 22],
      ['Foo', 42],
      ['Bar', 18]
    ]
  end

  # Specific tests against match and RHA assignment, not Unit
  describe '#match' do
    it 'will use identity for empty function matches' do
      result = Qo.match(people.first, Qo.m(:*))

      expect(result).to eq(people.first)
    end

    it 'will send the matching object into a match node function' do
      result = Qo.match(people.first,
        Qo.m(:*) { |person| person.name }
      )

      expect(result).to eq(people.first.name)
    end

    it 'will work with procs like sane Ruby too' do
      result = Qo.match(people.first,
        Qo.m(:*, &:name)
      )

      expect(result).to eq(people.first.name)
    end

    it 'will return nil if nothing is found' do
      result = Qo.match(people.first, Qo.m(:non_existant_method))

      expect(result).to eq(nil)
    end

    it 'can deconstruct array to array matches' do
      result = Qo.match(people_arrays.first,
        Qo.m(String, Integer) { |name, age| "#{name} is #{age} years old" }
      )

      expect(result).to eq("Robert is 22 years old")
    end

    # _technically_ it can. You still need to specify all the params and this is
    # far more of a Rubyism than a Qo'ism. You could also play default args here
    # if you're really so inclined.
    it 'can deconstruct hash to hash matches' do
      result = Qo.match(people.first.to_h,
        Qo.m(name: :*, age: 22) { |name:, age:| age + 1 }
      )

      expect(result).to eq(23)
    end
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

  describe '#dig' do
    it 'can get at deep data' do
      matcher = Qo.dig('a.b.c', Qo.or(1..5, 15..25))
      target  = {a: {b: {c: 1}}}

      expect(matcher.call(target)).to eq(true)
    end
  end

  describe '#count_by' do
    it 'counts without a block using an identity function' do
      expect(Qo.count_by([1,2,3,2,2,2,1])).to eq({
        1 => 2,
        2 => 4,
        3 => 1
      })
    end

    it 'counts with a block' do
      expect(Qo.count_by([1,2,3,2,2,2,1], &:even?)).to eq({
        false => 3,
        true  => 4
      })
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

    describe '#case_match?' do
      it 'basically wraps `===`' do
        expect(qo_matcher.send(:case_match?, 'Foo', /^F/)).to eq(true)
      end
    end

    describe '#wildcard_match?' do
      it 'can match against a wildcard' do
        expect(qo_matcher.send(:wildcard_match?, :*)).to eq(true)
      end

      context 'When provided a value not matching the wildcard' do
        it 'will not match' do
          expect(qo_matcher.send(:wildcard_match?, nil)).to eq(false)
        end
      end
    end

    describe '#method_send' do
      it 'will return the result of sending a method' do
        expect(qo_matcher.send(:method_send, 1, :odd?)).to eq(true)
      end

      context 'When the target does not respond to the matcher' do
        it 'returns false' do
          expect(qo_matcher.send(:method_send, 1, :i_do_not_exist)).to eq(false)
        end
      end

      context 'When the matcher does not respond to to_sym' do
        it 'returns false' do
          expect(qo_matcher.send(:method_send, 1, /i don't symbolize well/)).to eq(false)
        end
      end
    end

    describe '#method_matches?' do
      it 'just wraps #method_send with a boolean coercion' do
        expect(qo_matcher.send(:method_matches?, 1, :succ)).to eq(true)
      end
    end

    describe '#match_with' do
      it 'wraps the collection match' do
        expect(qo_matcher.send(:match_with, [1,2,3], :even?.to_proc)).to eq(false)
      end
    end

    describe 'Matcher functions' do
      describe '#array_against_array_matcher' do
        it 'generates a function to match an array against matchers at the same index' do
          matcher_fn = qo_matcher.send(:array_against_array_matcher, [1, 1])
          expect(matcher_fn.call(Integer, 1)).to eq(true)
        end

        context 'When given a wildcard' do
          it 'will always match' do
            matcher_fn = qo_matcher.send(:array_against_array_matcher, [1, 1])
            expect(matcher_fn.call(:*, 1)).to eq(true)
          end
        end
      end

      describe '#array_against_object_matcher' do
        it 'generates a function to match an array against a collection of matchers' do
          matcher_fn = qo_matcher.send(:array_against_object_matcher, 1)
          expect(matcher_fn.call(Integer)).to eq(true)
        end

        context 'When given a wildcard' do
          it 'will always match' do
            matcher_fn = qo_matcher.send(:array_against_object_matcher, 1)
            expect(matcher_fn.call(:*)).to eq(true)
          end
        end

        context 'When given a predicate method' do
          it 'will call that method on the target' do
            matcher_fn = qo_matcher.send(:array_against_object_matcher, 1)
            expect(matcher_fn.call(:even?)).to eq(false)
          end
        end
      end

      describe '#hash_against_hash_matcher' do
        it 'generates a function to match a hash pair against another hash' do
          matcher_fn = qo_matcher.send(:hash_against_hash_matcher, {name: 'Foobar'})
          expect(matcher_fn.call([:name, /Foo/])).to eq(true)
        end

        context 'When given a wildcard' do
          it 'will always match' do
            matcher_fn = qo_matcher.send(:hash_against_hash_matcher, {name: 'Foobar'})
            expect(matcher_fn.call([:name, :*])).to eq(true)
          end
        end

        context 'When given a deep match' do
          it 'will match' do
            matcher_fn = qo_matcher.send(:hash_against_hash_matcher, {a: {b: {c: 1}}})
            expect(matcher_fn.call([:a, {b: {c: 1..10}}])).to eq(true)
          end
        end
      end

      describe '#hash_against_object_matcher' do
        it 'generates a function to match a hash pair against an object using the key as a method and a value as a matcher' do
          matcher_fn = qo_matcher.send(:hash_against_object_matcher, 1)
          expect(matcher_fn.call([:to_s, '1'])).to eq(true)
        end

        context 'When given a wildcard' do
          it 'will always match' do
            matcher_fn = qo_matcher.send(:hash_against_object_matcher, 1)
            expect(matcher_fn.call([:to_s, :*])).to eq(true)
          end
        end
      end
    end
  end
end

require "spec_helper"

# TODO: Refactor into a more example case driven variant of the Public API for
# Qo.
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
      result = Qo.match(people.first, Qo.m(Any))

      expect(result).to eq(people.first)
    end

    it 'will send the matching object into a match node function' do
      result = Qo.match(people.first,
        Qo.m(Any) { |person| person.name }
      )

      expect(result).to eq(people.first.name)
    end

    it 'will work with procs like sane Ruby too' do
      result = Qo.match(people.first,
        Qo.m(Any, &:name)
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
        Qo.m(name: Any, age: 22) { |name:, age:| age + 1 }
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
          expect(Qo[/Rob/, Any] === matched_array).to eq(true)
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

            let(:query) { Qo[Any, 18..25] }

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
        expect(Qo[name: /^F/, age: Any] === matched_hash).to eq(true)
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
end

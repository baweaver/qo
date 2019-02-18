require "spec_helper"

RSpec.describe Qo::PatternMatchers::PatternMatch do
  let(:exhaustive) { false }

  let(:pattern_match) do
    Qo::PatternMatchers::PatternMatch.new(exhaustive: exhaustive) { |m|
      m.when(1) { |v| v + 4 }
      m.when(2) { |v| v * 2 }
      m.else    { |v| v }
    }
  end

  describe '#initialize' do
    it 'can be created' do
      expect(pattern_match).to be_a(Qo::PatternMatchers::PatternMatch)
    end
  end

  describe '#to_proc' do
    it 'returns a Proc' do
      expect(pattern_match.to_proc).to be_a(Proc)
    end
  end

  describe '#call' do
    it 'will run the matchers in sequence, calling the matched block' do
      expect(pattern_match.call(1)).to eq(5)
    end

    context 'When no match is found' do
      it 'will hit the default matcher' do
        expect(pattern_match.call(42)).to eq(42)
      end
    end

    context 'When no default matchers are given' do
      let(:pattern_match) { Qo::PatternMatchers::PatternMatch.new { |m| } }

      it 'will return nil' do
        expect(pattern_match.call(1)).to eq(nil)
      end
    end
  end

  describe '#exhaustive?' do
    it 'checks if a match is exhaustive' do
      expect(pattern_match.exhaustive?).to eq(false)
    end

    context 'When a match is set as exhaustive' do
      let(:exhaustive) { true }

      it 'will be an exhaustive match' do
        expect(pattern_match.exhaustive?).to eq(true)
      end
    end
  end

  describe '#exhaustive_no_default?' do
    it 'checks if a match is exhaustive and lacks a default branch' do
      expect(pattern_match.exhaustive_no_default?).to eq(false)
    end

    context 'When an exhaustive match is specified' do
      let(:exhaustive) { true }

      it 'will be false if there is a default' do
        expect(pattern_match.exhaustive_no_default?).to eq(false)
      end

      context 'When there is no default' do
        let(:pattern_match) do
          Qo::PatternMatchers::PatternMatch.new(exhaustive: exhaustive) { |m|
            m.when(1) { |v| v + 4 }
            m.when(2) { |v| v * 2 }
          }
        end

        it 'will raise a pessimistic error' do
          error_message = <<~ERROR
            Exhaustive match required: pattern does not specify all branches.
              Expected Branches: when, else
              Given Branches:    when, when
          ERROR

          expect {
            pattern_match.exhaustive_no_default?
          }.to raise_error(
            Qo::Exceptions::ExhaustiveMatchMissingBranches, error_message
          )
        end
      end
    end
  end

  # These are entirely for people to get ideas from. It uses the Public API
  # shorthand to be less formal than the above specs.
  #
  # I'll fill out a few more later.
  describe '[Examples]' do
    context 'When working with numbers' do
      let(:pattern_match) {
        Qo.match { |m|
          m.when(10..15, Any)      { |a, b| a * b }
          m.when(:even?, :odd?)    { |a, b| b - a }
          m.when(Integer, Integer) { |a, b| a + b }
          m.else { |v| v }
        }
      }

      it 'will match the first case with 11 and 5' do
        expect(pattern_match.call([11, 5])).to eq(55)
      end

      it 'will match the second case with 9 and 5' do
        expect(pattern_match.call([8, 5])).to eq(-3)
      end

      it 'will match the third case if we at least got Ints' do
        expect(pattern_match.call([1, 1])).to eq(2)
      end

      it 'will otherwise give us back whatever we passed in' do
        expect(pattern_match.call([nil, :foo])).to eq([nil, :foo])
      end
    end

    context 'When working with Strings' do
      let(:pattern_match) {
        Qo.match { |m|
          m.when(/foo/, Any) { |a, b| a + b }

          m.when(
            Qo.or(/ba/, /baz/), Any
          ) { |a, b| "#{a} really likes #{b}" }

          m.when(String, :empty?) { |a, b| "Well you're no fun #{a}, givin me a blank!" }
        }
      }

      it 'will match the first with foo and anything else' do
        expect(pattern_match.call(['foobar', 'baz'])).to eq('foobarbaz')
      end

      it 'will match the second with either ba or baz, then anything else' do
        expect(pattern_match.call(['baweaver', 'lemurs and tests'])).to eq('baweaver really likes lemurs and tests')
      end

      it 'will match the third if we give it a string and an empty' do
        expect(pattern_match.call(['String', ''])).to eq("Well you're no fun String, givin me a blank!")
      end

      it 'will return nil because we forgot a default. Tsk tsk.' do
        expect(pattern_match.call([nil, nil])).to eq(nil)
      end
    end

    context 'When working with destructured elements' do
      let(:pattern_match) {
        Qo::PatternMatchers::PatternMatch.new(destructure: true) { |m|
          m.when(name: /^F/) { |name, age| Person.new(name, age + 1) }
        }
      }

      it 'will destructure an object using the arguments to the associated block' do
        expect(pattern_match.call(Person.new('Foo', 42)).age).to eq(43)
      end
    end

    context 'When working with exhaustive matches' do
      let(:pattern_match) {
        Qo::PatternMatchers::PatternMatch.new(exhaustive: true) { |m|
          m.when(name: /^F/) { |person| person.age + 1 }
        }
      }

      it 'will raise an exception if not all branches are provided' do
        expected_error = <<~ERROR
          Exhaustive match required: pattern does not specify all branches.
            Expected Branches: when, else
            Given Branches:    when
        ERROR

        expect {
          pattern_match.call(Person.new('Foo', 42)).age
        }.to raise_error(Qo::Exceptions::ExhaustiveMatchMissingBranches, expected_error)
      end

      context 'When all branches are provided' do
        let(:pattern_match) {
          Qo::PatternMatchers::PatternMatch.new(exhaustive: true) { |m|
            m.when(name: /^F/) { |person| person.age + 1 }
            m.else { 7 }
          }
        }

        it 'will proceed as normal' do
          expect(pattern_match.call(Person.new('Foo', 42))).to eq(43)
        end
      end

      context 'When given a default branch' do
        let(:pattern_match) {
          Qo::PatternMatchers::PatternMatch.new(exhaustive: true) { |m|
            m.else { |person| person.age + 1 }
          }
        }

        it 'will ignore the strict requirement for all branches, as default satisfies exhaustive' do
          expect(pattern_match.call(Person.new('Foo', 42))).to eq(43)
        end
      end
    end
  end
end

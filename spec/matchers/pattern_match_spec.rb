require "spec_helper"

RSpec.describe Qo::Matchers::PatternMatch do
  let(:guard_matchers) do
    [
      Qo::Matchers::GuardBlockMatcher.new(1) { |v| v + 4 },
      Qo::Matchers::GuardBlockMatcher.new(2) { |v| v * 2 },
      Qo::Matchers::GuardBlockMatcher.new(Any),
    ]
  end

  let(:pattern_match) { Qo::Matchers::PatternMatch.new(*guard_matchers) }

  describe '#initialize' do
    it 'can be created' do
      expect(pattern_match).to be_a(Qo::Matchers::PatternMatch)
    end

    context 'When passed a non-guard matcher' do
      let(:guard_matchers) { [Qo[1]] }

      it 'will fail' do
        expect { pattern_match }.to raise_error(Qo::Exceptions::NotAllGuardMatchersProvided)
      end
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
      let(:guard_matchers) { [] }

      it 'will return nil' do
        expect(pattern_match.call(1)).to eq(nil)
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
        Qo.match(
          Qo.m(10..15, Any)       { |a, b| a * b },
          Qo.m(:even?, :odd?)    { |a, b| b - a },
          Qo.m(Integer, Integer) { |a, b| a + b },
          Qo.m(Any)
        )
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
        Qo.match(
          Qo.m(/foo/, Any) { |a, b| a + b },

          Qo.m(
            Qo.or(/ba/, /baz/), Any
          ) { |a, b| "#{a} really likes #{b}" },

          Qo.m(String, :empty?) { |a, b| "Well you're no fun #{a}, givin me a blank!" }
        )
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
  end
end

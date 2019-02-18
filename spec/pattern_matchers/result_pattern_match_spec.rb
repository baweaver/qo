require "spec_helper"

RSpec.describe Qo::PatternMatchers::ResultPatternMatch do
  let(:exhaustive) { false }

  let(:pattern_match) do
    Qo::PatternMatchers::ResultPatternMatch.new(exhaustive: exhaustive) { |m|
      m.success(Integer) { |v| v + 1 }
      m.success(String)  { |v| "OHAI #{v}!" }
      m.success          { |v| 42 }
      m.failure          { |v| "AGH! CRASH!" }
    }
  end

  describe '#initialize' do
    it 'can be created' do
      expect(pattern_match).to be_a(Qo::PatternMatchers::ResultPatternMatch)
    end
  end

  describe '#to_proc' do
    it 'returns a Proc' do
      expect(pattern_match.to_proc).to be_a(Proc)
    end
  end

  describe '#call' do
    context 'Successful results' do
      it 'will call the first success branch when passed an integer' do
        expect(pattern_match.call([:ok, 1])).to eq(2)
      end

      it 'will call the second success branch when passed a string' do
        expect(pattern_match.call([:ok, 'lemur'])).to eq('OHAI lemur!')
      end

      it 'will otherwise call the success branch not matching any other condition' do
        expect(pattern_match.call([:ok, :answer?])).to eq(42)
      end
    end

    context 'Failed result' do
      it 'will call the failure branch when given a failed result' do
        expect(pattern_match.call([:err, :answer?])).to eq("AGH! CRASH!")
      end
    end

    context 'When no match is found' do
      it 'will return nil' do
        expect(pattern_match.call([:wat?, :wat?])).to eq(nil)
      end

      context 'When the match is required to be exhaustive' do
        let(:exhaustive) { true }

        it 'will raise an error' do
          expect {
            pattern_match.call([:wat?, :wat?])
          }.to raise_error(Qo::Exceptions::ExhaustiveMatchNotMet)
        end
      end
    end
  end
end

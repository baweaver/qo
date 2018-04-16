require "spec_helper"

RSpec.describe Qo::Matchers::ArrayMatcher do
  let(:type) { 'and' }
  let(:array_matchers) { [1] }

  let(:qo_matcher) { Qo::Matchers::ArrayMatcher.new(type, *array_matchers) }

  describe '#initialize' do
    it 'can be created' do
      expect(qo_matcher).to be_a(Qo::Matchers::ArrayMatcher)
    end
  end

  describe '#to_proc' do
    it 'returns a proc' do
      expect(qo_matcher.to_proc).to be_a(Proc)
    end
  end

  describe '#call' do
    it 'will return true when there is a literal match' do
      expect(qo_matcher.call([1])).to eq(true)
    end

    context 'When matching an Array with an Array' do
      let(:array_matchers) { [Integer, 1..10, :odd?] }

      it 'will perform an indexed match' do
        expect(qo_matcher.call([1, 2, 3])).to eq(true)
      end
    end

    context 'When matching an Array with an Object' do
      let(:array_matchers) { [Integer, 1..10, :odd?] }

      it 'will perform a compound search' do
        expect(qo_matcher.call(1)).to eq(true)
      end
    end
  end

  describe '[Examples]' do
    # TODO
  end

  # Methods tested or referenced here should not be used in public consumption
  # as they're quite liklely to change over time.
  describe 'Private API' do
    describe '#match_value?' do
      it 'will wildcard match' do
        expect(qo_matcher.send(:match_value?, 1, :*)).to eq(true)
      end

      it 'will case match' do
        expect(qo_matcher.send(:match_value?, 1, 1..10)).to eq(true)
        expect(qo_matcher.send(:match_value?, 1, Integer)).to eq(true)
      end

      it 'will method match' do
        expect(qo_matcher.send(:match_value?, 1, :odd?)).to eq(true)
      end
    end
  end
end

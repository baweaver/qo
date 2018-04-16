require "spec_helper"

RSpec.describe Qo::Matchers::GuardBlockMatcher do
  let(:array_matchers) { [1] }
  let(:keyword_matchers) { {} }
  let(:fn) { -> v { v } }

  let(:qo_matcher) { Qo::Matchers::GuardBlockMatcher.new(*array_matchers, **keyword_matchers, &fn) }

  describe '#initialize' do
    it 'can be created' do
      expect(qo_matcher).to be_a(Qo::Matchers::GuardBlockMatcher)
    end
  end

  describe '#to_proc' do
    let(:matcher_fn) { qo_matcher.to_proc }

    it 'returns a proc' do
      expect(matcher_fn).to be_a(Proc)
    end

    context 'When the guard does not match' do
      it 'will return a false status tuple' do
        expect(matcher_fn.call(2)).to eq([false, false])
      end
    end

    context 'When the guard passes' do
      it 'will pass the match target to the block and return the result' do
        expect(matcher_fn.call(1)).to eq([true, 1])
      end
    end
  end

  describe '[Examples]' do
    # TODO
  end
end

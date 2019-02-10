# require "spec_helper"

# RSpec.describe Qo::Matchers::BaseMatcher do
#   let(:type) { 'and' }
#   let(:array_matchers) { [] }
#   let(:keyword_matchers) { {} }

#   let(:qo_matcher) { Qo::Matchers::BaseMatcher.new(type, array_matchers, keyword_matchers) }

#   describe '#initialize' do
#     it 'can be created' do
#       expect(qo_matcher).to be_a(Qo::Matchers::BaseMatcher)
#     end
#   end

#   describe '#to_proc' do
#     it 'returns a proc' do
#       expect(qo_matcher.to_proc).to be_a(Proc)
#     end
#   end

#   describe '#call' do
#     it 'attempts to call its child proc' do
#       expect(qo_matcher).to receive(:to_proc).and_return(Proc.new { |v| v })

#       expect(qo_matcher.to_proc.call(1)).to eq(1)
#     end
#   end

#   # Methods tested or referenced here should not be used in public consumption
#   # as they're quite liklely to change over time.
#   describe 'Private API' do
#     describe '#match_with' do
#       it 'will run the associated matcher' do
#         expect(
#           qo_matcher.send(:match_with, [1,2,3]) { |v| v.is_a?(Integer) }
#         ).to eq(true)
#       end
#     end

#     describe '#case_match?' do
#       it 'wraps ===' do
#         expect(qo_matcher.send(:case_match?, 'foobar', /foo/)).to eq(true)
#       end
#     end

#     describe '#method_send' do
#       it 'sends a method to a target' do
#         expect(qo_matcher.send(:method_send, 1, :odd?)).to eq(true)
#       end

#       context 'When the matcher cannot be coerced to a symbol' do
#         it 'will return false' do
#           expect(qo_matcher.send(:method_send, 1, /ha, no/)).to eq(false)
#         end
#       end

#       context 'When the target does not respond to the matcher as a method name' do
#         it 'will return false' do
#           expect(qo_matcher.send(:method_send, 1, :nope)).to eq(false)
#         end
#       end
#     end

#     describe '#method_matches?' do
#       it 'is a boolean coercion of #method_send' do
#         expect(qo_matcher.send(:method_matches?, 1, :odd?)).to eq(true)
#       end
#     end
#   end
# end

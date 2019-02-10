# require "spec_helper"

# RSpec.describe Qo::Matchers::HashMatcher do
#   let(:type) { 'and' }
#   let(:keyword_matchers) { {age: 42} }

#   let(:qo_matcher) { Qo::Matchers::HashMatcher.new(type, **keyword_matchers) }

#   describe '#initialize' do
#     it 'can be created' do
#       expect(qo_matcher).to be_a(Qo::Matchers::HashMatcher)
#     end
#   end

#   describe '#to_proc' do
#     it 'returns a proc' do
#       expect(qo_matcher.to_proc).to be_a(Proc)
#     end
#   end

#   describe '#call' do
#     it 'will return true when there is a literal match' do
#       expect(qo_matcher.call(age: 42)).to eq(true)
#     end

#     context 'When matching a Hash with a Hash' do
#       let(:keyword_matchers) { {name: /^f/, age: 30..50} }

#       it 'will perform an intersectional match' do
#         expect(qo_matcher.call(name: 'foo', age: 42)).to eq(true)
#       end
#     end

#     context 'When matching a Hash with an Object' do
#       it 'will perform a property match' do
#         expect(qo_matcher.call(Person.new('foo', 42))).to eq(true)
#       end
#     end
#   end

#   describe '[Examples]' do
#     # TODO
#   end

#   # Methods tested or referenced here should not be used in public consumption
#   # as they're quite liklely to change over time.
#   describe 'Private API' do
#     let(:person) { Person.new('foo', 42) }

#     describe '#match_hash_value' do
#       it 'will return false unless the key is present in the other hash' do
#         expect(
#           qo_matcher.send(:match_hash_value?, {a: 1}, :b, Any)
#         ).to eq(false)
#       end

#       it 'will return true on a wildcard match' do
#         expect(
#           qo_matcher.send(:match_hash_value?, {a: 1}, :a, Any)
#         ).to eq(true)
#       end

#       it 'will recurse if both the matcher and target are Hashes' do
#         expect(qo_matcher).to receive(:hash_recurse).and_call_original

#         expect(
#           qo_matcher.send(:match_hash_value?, {a: {b: 1}}, :a, {b: 1})
#         ).to eq(true)
#       end

#       it 'will return true if the value on the target for the match key case matches' do
#         expect(
#           qo_matcher.send(:match_hash_value?, {a: 10}, :a, 10..20)
#         ).to eq(true)
#       end

#       it 'will return true for a predicate match' do
#         expect(
#           qo_matcher.send(:match_hash_value?, {a: 10}, :a, :even?)
#         ).to eq(true)
#       end
#     end

#     describe '#match_object_value?' do
#       it 'will return false unless the target responds to the match property' do
#         expect(
#           qo_matcher.send(:match_object_value?, person, :nope, Any)
#         ).to eq(false)
#       end

#       it 'will return true for a wildcard match' do
#         expect(
#           qo_matcher.send(:match_object_value?, person, :name, Any)
#         ).to eq(true)
#       end

#       it 'will return true when the method return case matches with the matcher' do
#         expect(
#           qo_matcher.send(:match_object_value?, person, :age, 30..50)
#         ).to eq(true)
#       end
#     end

#     describe '#hash_case_match?' do
#       it 'will case match directly against the provided key' do
#         expect(
#           qo_matcher.send(:hash_case_match?, {a: 1}, :a, 1..5)
#         ).to eq(true)
#       end

#       it 'will attempt to match with a string variant of the key' do
#         expect(
#           qo_matcher.send(:hash_case_match?, {'a' => 1}, :a, 1..5)
#         ).to eq(true)
#       end
#     end

#     describe '#hash_method_predicate_match?' do
#       it 'will predicate match against the key applied to the target' do
#         expect(
#           qo_matcher.send(:hash_method_predicate_match?, {a: 1}, :a, :odd?)
#         ).to eq(true)
#       end
#     end

#     describe '#hash_method_case_match?' do
#       it 'will case match directly against the provided key' do
#         expect(
#           qo_matcher.send(:hash_method_case_match?, person, :age, 30..50)
#         ).to eq(true)
#       end
#     end
#   end
# end

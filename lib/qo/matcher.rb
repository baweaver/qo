module Qo
  class Matcher
    def initialize(type, *array_matchers, **keyword_matchers)
      @match_method     = get_match_method(type)
      @array_matchers   = array_matchers
      @keyword_matchers = keyword_matchers
    end

    def to_proc
      @array_matchers.empty? ?
        match_against_hash(@keyword_matchers) :
        match_against_array(@array_matchers)
    end

    def call(other)
      self.to_proc.call(other)
    end

    alias_method :===, :call
    alias_method :[],  :call

    private def match_against_array(matchers)
      -> other_object {
        other_object.is_a?(::Array) ?
          matchers.each_with_index.public_send(@match_method, &array_matches_array_fn(other_object)) :
          matchers.public_send(@match_method, &array_matches_object_fn(other_object))
      }
    end

    private def match_against_hash(matchers)
      -> other_object {
        other_object.is_a?(::Hash) ?
          matchers.public_send(@match_method, &hash_matches_hash_fn(other_object)) :
          matchers.public_send(@match_method, &hash_matches_object_fn(other_object))
      }
    end

    private def get_match_method(name)
      case name
      when 'and' then :all?
      when 'or'  then :any?
      when 'not' then :none?
      else :all?
      end
    end

    private def array_matches_array_fn(other_object)
      -> matcher, i {
        matcher == WILDCARD_MATCH || matcher === other_object[i]
      }
    end

    private def array_matches_object_fn(other_object)
      -> matcher {
        matcher == WILDCARD_MATCH || other_object.public_send(matcher)
      }
    end

    private def hash_matches_hash_fn(other_object)
      -> match_key, match_value {
        match_value == WILDCARD_MATCH ||
        match_value === other_object[match_key] ||
        match_value === other_object[match_key.to_s]
      }
    end

    private def hash_matches_object_fn(other_object)
      -> match_key, match_value {
        match_value == WILDCARD_MATCH || match_value === other_object.public_send(match_key)
      }
    end
  end
end

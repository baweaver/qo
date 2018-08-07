module Qo
  module Helpers
    # A curried variant of Hash#dig meant to be passed as a matcher util.
    #
    # @note This method will attempt to coerce path segments to Symbols
    #       if unsuccessful in first dig.
    #
    # @param path_map [String]
    #   Dot-delimited path
    #
    # @param expected_value [Any]
    #   Matcher
    #
    # @return [Proc]
    #     Hash -> Bool # Status of digging against the hash
    def dig(path_map, expected_value)
      Proc.new { |hash|
        segments = path_map.split('.')

        expected_value === hash.dig(*segments) ||
        expected_value === hash.dig(*segments.map(&:to_sym))
      }
    end

    # Counts by a function. This is entirely because I hackney this everywhere in
    # pry anyways, so I want a function to do it for me already.
    #
    # @param targets [Array[Any]]
    #   Targets to count
    #
    # @param &fn [Proc]
    #   Function to define count key
    #
    # @return [Hash[Any, Integer]]
    #   Counts
    def count_by(targets, &fn)
      fn ||= -> v { v }

      targets.each_with_object(Hash.new(0)) { |target, counts|
        counts[fn[target]] += 1
      }
    end
  end
end

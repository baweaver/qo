require "qo/version"
require 'qo/matcher'

module Qo
  WILDCARD_MATCH = :*

  def self.and(*array_matchers, **keyword_matchers)
    Qo::Matcher.new('and', *array_matchers, **keyword_matchers)
  end

  def self.[](*array_matchers, **keyword_matchers)
    Qo::Matcher.new('and', *array_matchers, **keyword_matchers)
  end

  def self.or(*array_matchers, **keyword_matchers)
    Qo::Matcher.new('or', *array_matchers, **keyword_matchers)
  end

  def self.not(*array_matchers, **keyword_matchers)
    Qo::Matcher.new('not', *array_matchers, **keyword_matchers)
  end
end

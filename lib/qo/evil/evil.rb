require 'qo/evil/matcher'

module Qo
  module Evil
    def self.and(*as, **ks)
      Qo::Evil::Matcher.new('and', *as, *ks)
    end

    def self.or(*as, **ks)
      Qo::Evil::Matcher.new('or', *as, *ks)
    end

    def self.not(*as, **ks)
      Qo::Evil::Matcher.new('not', *as, *ks)
    end
  end
end

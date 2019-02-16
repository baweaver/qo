module Qo
  # Classes that allow for the destructuring of values from an object, meant
  # to emulate Javascript object destructuring. While this is a very powerful
  # expressive feature, it can also slow down execution by a small amount, so
  # use destructuring wisely.
  #
  # @see https://medium.com/rubyinside/destructuring-in-ruby-9e9bd2be0360
  #
  # @author baweaver
  # @since 1.0.0
  module Destructurers
  end
end

require 'qo/destructurers/destructurer'

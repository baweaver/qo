# Qo

Short for Query Object, my play at Ruby pattern matching and fluent querying

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'qo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install qo

## How does it work?

Triple equals black magic, mostly.

Want to understand more of how that works? Check out this post: https://medium.com/rubyinside/triple-equals-black-magic-d934936a6379

The original inspiration was from a chat I'd had with a few other Rubyists about pattern matching, which led to this experiment: https://gist.github.com/baweaver/611389c41c9005d025fb8e55448bf5f5

Fast forward a few months and I kind of wanted to make it real, so here it is. Introducing Qo!

## Usage

Qo supports three main types of queries: `and`, `or`, and `not`.

Most examples are written in terms of `and` and its alias `[]`. `[]` is mostly used for portable syntax:

```ruby
Qo[/Rob/, 22]

# ...is functionally the same as:
Qo.and(/Rob/, 22)
```

### Qo'isms

Qo has a few Qo'isms, mainly based around triple equals in Ruby. See the above articles for tutorials on that count.

It also has a wildcard, `:*`, which will match any value:

```ruby
Qo[/Rob/, :*] === ['Robert', 22] # true
```

As it responds to triple equals, that also means it can be used with `case` statements in a play at pattern matching:

```ruby
case ['Robert', 22]
when Qo[:*, 10..19] then 'teenager'
when Qo[:*. 20..99] then 'adult'
else 'who knows'
end
```

Though chances are you don't have tuple-like code, you have objects. How about we play with those:

```ruby
# Person has a name and an age attr

case robert
when Qo[age: 10..19] then 'teenager'
when Qo[age: 20..99] then 'adult'
else 'objection!'
end
```

### Arrays

As Qo returns an Object that responds to `to_proc` it can be used with several Enumerable methods:

```ruby
people = [
  ['Robert', 22],
  ['Roberta', 22],
  ['Foo', 42],
  ['Bar', 18]
]

people.select(&Qo[:*, 15..25]) # => [["Robert", 22], ["Roberta", 22], ["Bar", 18]]
```

### Hashes and Objects

If you have a lot of JSON or Objects, good news! Qo has tricks:

```ruby
people = [
  Person.new('Robert', 22),
  Person.new('Roberta', 22),
  Person.new('Foo', 42),
  Person.new('Bar', 17),
]

people.select(&Qo[name: /Rob/]) # => [Person('Robert', 22), Person('Roberta', 22)]
```

Qo tries to be clever though, it assumes Symbol keys first and then String keys:

```ruby
require 'json'
require 'net/http'
posts = JSON.parse(
  Net::HTTP.get(URI("https://jsonplaceholder.typicode.com/posts")),symbolize_names: true
)

posts.select(&Qo[userId: 1])
```

Nifty!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/baweaver/qo. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Qo project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/baweaver/qo/blob/master/CODE_OF_CONDUCT.md).

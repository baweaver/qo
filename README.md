# Qo

[![Build Status](https://travis-ci.org/baweaver/qo.svg?branch=master)](https://travis-ci.org/baweaver/qo)
[![Maintainability](https://api.codeclimate.com/v1/badges/186e9cbb7003842acaf0/maintainability)](https://codeclimate.com/github/baweaver/qo/maintainability)
[![Gem Version](https://badge.fury.io/rb/qo.svg)](https://badge.fury.io/rb/qo)

Short for Query Object, my play at Ruby pattern matching and fluent querying, [pronounced "Q-whoah"](img/whoa_lemur.png).

![Qo Lemur logo](img/qo_logo.png)

[Read the Docs for more detailed information](https://baweaver.github.io/qo/)

## How does it work?

Mostly by using Ruby language features like `to_proc` and `===`.

There's an article explaining most of the base mechanics behind Qo:

[For Want of Pattern Matching in Ruby - The Creation of Qo](https://medium.com/@baweaver/for-want-of-pattern-matching-in-ruby-the-creation-of-qo-c3b267109b25)

Most of it, though, utilizes Triple Equals. If you're not familiar with what all you can do with it in Ruby, I would encourage you to read this article as well:

[Triple Equals Black Magic](https://medium.com/rubyinside/triple-equals-black-magic-d934936a6379)

The original inspiration was from a chat I'd had with a few other Rubyists about pattern matching, which led to this experiment:

[Having fun with M and Q](https://gist.github.com/baweaver/611389c41c9005d025fb8e55448bf5f5)

Fast forward a few months and I kind of wanted to make it real, so here it is. Introducing Qo!

## Usage

### Quick Start

Qo is used for pattern matching in Ruby. All Qo matchers respond to `===` and `to_proc` meaning they can be used with `case` and Enumerable functions alike:


```ruby
case ['Foo', 42]
when Qo[:*, 42] then 'Truly the one answer'
else nil
end

# Run a select like an AR query, getting the age attribute against a range
people.select(&Qo[age: 18..30])
```

How about some pattern matching? There are two styles:

#### Pattern Match

The original style

```
# How about some "right-hand assignment" pattern matching
name_longer_than_three      = -> person { person.name.size > 3 }
people_with_truncated_names = people.map(&Qo.match(
  Qo.m(name_longer_than_three) { |person| Person.new(person.name[0..2], person.age) },
  Qo.m(:*) # Identity function, catch-all
))

# And standalone like a case:
Qo.match(people.first,
  Qo.m(age: 10..19) { |person| "#{person.name} is a teen that's #{person.age} years old" },
  Qo.m(:*) { |person| "#{person.name} is #{person.age} years old" }
)
```

#### Pattern Match Block

The new style, likely to take over in `v1.0.0` after testing:

```ruby
name_longer_than_three      = -> person { person.name.size > 3 }
people_with_truncated_names = people.map(&Qo.match { |m|
  m.when(name_longer_than_three) { |person| Person.new(person.name[0..2], person.age) }
  m.else(&:itself)
})

# And standalone like a case:
Qo.match(people.first) { |m|
  m.when(age: 10..19) { |person| "#{person.name} is a teen that's #{person.age} years old" }
  m.else { |person| "#{person.name} is #{person.age} years old" }
}
```

(More details coming on the difference and planned 1.0.0 APIs)

### Qo'isms

Qo supports three main types of queries: `and`, `or`, and `not`.

Most examples are written in terms of `and` and its alias `[]`. `[]` is mostly used for portable syntax:

```ruby
Qo[/Rob/, 22]

# ...is functionally the same as an and query, which uses `all?` to match
Qo.and(/Rob/, 22)

# This is shorthand for
Qo::Matchers::BaseMatcher.new('and', /Rob/, 22)

# An `or` matcher uses the same shorthand as `and` but uses `any?` behind the scenes instead:
Qo.or(/Rob/, 22)

# Same with not, except it uses `none?`
Qo.not(/Rob/, 22)
```

Qo has a few Qo'isms, mainly based around triple equals in Ruby. See the above articles for tutorials on that count.

We will assume the following data:

```ruby
people_arrays = [
  ['Robert', 22],
  ['Roberta', 22],
  ['Foo', 42],
  ['Bar', 18]
]

people_objects = [
  Person.new('Robert', 22),
  Person.new('Roberta', 22),
  Person.new('Foo', 42),
  Person.new('Bar', 17),
]
```

### 1 - Wildcard Matching

Qo has a concept of a Wildcard, `:*`, which will match against any value

```ruby
Qo[:*, :*] === ['Robert', 22] # true
```

A single wildcard will match anything, and can frequently be used as an always true:

```ruby
Qo[:*] === :literally_anything_here
```

### 2 - Array Matching

The first way a Qo matcher can be defined is by using `*varargs`:

```ruby
Qo::Matchers::BaseMatcher(type, *varargs, **kwargs)
```

This gives us the `and` matcher shorthand for array matchers.

#### 2.1 - Array matched against an Array

When an Array matcher is run against an Array, it will compare elements by index in the following priority:

1. Was a wildcard provided?
2. Does it case match (`===`)?
3. Does it have a predicate method by that name that matches?

This functionality is left biased and permissive, meaning that if the right side of the argument is longer it will ignore those items in the match. If it's shorter? Not so much.

##### 2.1.1 - Wildcard provided

```ruby
# Standalone

Qo[:*, :*] === ['Robert', 22]
# => true

# Case statement

case ['Roberta', 22]
when Qo[:*, :*] then 'it matched'
else 'will not ever be reached'
end
# => 'it matched'

# Select

people_arrays.select(&Qo[:*, :*])
# => [['Robert', 22], ['Roberta', 22], ['Foo', 42], ['Bar', 18]]
```

##### 2.1.2 - Case Match present

We've seen some case matching so far with `Range` and `Regex`:

```ruby
# Standalone

Qo[/Rob/, :*] === ['Robert', 22]
# => true

# Case statement

case ['Roberta', 22]
when Qo[:*, 0..9] then 'child'
when Qo[:*, 10..19] then 'teen'
when Qo[:*, 20..99] then 'adult'
else 'not sure'
end
# => 'adult'

# Select

people_arrays.select(&Qo[:*, 10..19])
# => [['Bar', 18]]
```

##### 2.1.3 - Predicate Method matched

If no wildcard or case match is found, it will attempt to see if a predicate method by the same name exists, call it, and check the result:

```ruby
dirty_values = [nil, '', true]

# Standalone

Qo[:nil?] === [nil]
# => true, though you could also just use Qo[nil]

# Case statement

case ['Roberta', nil]
when Qo[:*, :nil?] then 'no age'
else 'not sure'
end
# => 'no age'

# Select

people_arrays.select(&Qo[:*, :even?])
# => [["Robert", 22], ["Roberta", 22], ["Foo", 42], ["Bar", 18]]
```

#### 2.2 - Array matched against an Object

When an Array matcher is matched against anything other than an Array it will follow the priority:

1. Was a wildcard provided?
2. Does it case match (`===`)?
3. Does it have a predicate method by that name that matches?

Every argument provided will be run against the target object.

##### 2.2.1 - Wildcard provided

A wildcard in an Array to Object match is functionally an always true, but can be used as such:

```ruby
Qo[:*] === :literally_anything_here
```

##### 2.2.2 - Case Match present

```ruby
# Standalone

Qo[Integer, 15..25] === 20
# => true

# Case statement - functionally indistinguishable from a regular case statement

# Select

[nil, '', 10, 'string'].select(&Qo.or(/str/, 10..20))
# => [10, "string"]
```

##### 2.2.3 - Predicate Method matched

Now this is where some of the fun starts in

```ruby
# Standalone

Qo.or(:nil?, :empty?) === nil
# => true
Qo.not(:nil?, :empty?) === nil
# => false

# Case statement

case 42
when Qo[Integer, :even?, 40..50] then 'oddly specific number criteria'
else 'nope'
end
# => "oddly specific number criteria"

# Reject

[nil, '', 10, 'string'].reject(&Qo.or(:nil?, :empty?))
# => [10, "string"]
```

### 3 - Hash Matching

#### 3.1 - Hash matched against a Hash

1. Does the key exist on the other hash?
2. Are the match value and match target hashes?
3. Was a wildcard value provided?
4. Does the target object's value case match against the match value?
5. Does the target object's value predicate match against the match value?
6. What about the String version of the match key? Abort if it can't coerce.

##### 3.1.1 - Key present

Checks to see if the key is even present on the other object, false if not.

##### 3.1.2 - Match value and target are hashes

If both the match value (`match_key: matcher`) and the match target are hashes, Qo will begin a recursive descent starting at the match key until it finds a matcher to try out:

```ruby
Qo[a: {b: {c: 5..15}}] === {a: {b: {c: 10}}}
# => true

# Na, no fun. Deeper!
Qo.and(a: {
  f: 5..15,
  b: {
    c: /foo/,
    d: 10..30
  }
}).call(a: {
  f: 10,
  b: {
    c: 'foobar',
    d: 20
  }
})
# => true

# It can get chaotic with `or` though. Anything anywhere in there matches and
# it'll pass.
Qo.or(a: {
  f: false,
  b: {
    c: /nope/,
    d: 10..30
  }
}).call(a: {
  f: 10,
  b: {
    c: 'foobar',
    d: 20
  }
})
```

##### 3.1.3 - Wildcard provided

As with other wildcards, if the value matched against is a wildcard it'll always get through:

```ruby
Qo[name: :*] === {name: 'Foo'}
# => true
```

##### 3.1.4 - Case match present

If a case match is present for the key, it'll try and compare:

```ruby
# Standalone

Qo[name: /Foo/] === {name: 'Foo'}
# => true

# Case statement

case {name: 'Foo', age: 42}
when Qo[age: 40..50] then 'Gotcha!'
else 'nope'
end
# => "Gotcha!"

# Select

people_hashes = people_arrays.map { |n, a| {name: n, age: a} }
people_hashes.select(&Qo[age: 15..25])
# => [{:name=>"Robert", :age=>22}, {:name=>"Roberta", :age=>22}, {:name=>"Bar", :age=>18}]
```

##### 3.1.5 - Predicate match present

Much like our array friend above, if a predicate style method is present see if it'll work

```ruby
# Standalone

Qo[name: :empty?] === {name: ''}
# => true

# Case statement

case {name: 'Foo', age: nil}
when Qo[age: :nil?] then 'No age provided!'
else 'nope'
end
# => "No age provided!"

# Reject

people_hashes = people_arrays.map { |(n,a)| {name: n, age: a} } << {name: 'Ghost', age: nil}
people_hashes.reject(&Qo[age: :nil?])
# => [{:name=>"Robert", :age=>22}, {:name=>"Roberta", :age=>22}, {:name=>"Bar", :age=>18}]
```

Careful though, if the key doesn't exist that won't match. I'll have to consider this one later.

##### 3.1.6 - String variant present

Coerces the key into a string if possible, and sees if that can provide a valid case match

#### 3.2 - Hash matched against an Object

1. Does the object respond to the match key?
2. Was a wildcard value provided?
3. Does the result of sending the match key as a method case match the provided value?
4. Does a predicate method exist for it?

##### 3.2.1 - Responds to match key

If it doesn't know how to deal with it, false out.

##### 3.2.2 - Wildcard provided

Same as other wildcards, but if the object doesn't respond to the method you specify it'll have false'd out before it reaches here.

##### 3.2.3 - Case match present

This is where we can get into some interesting code, much like the hash selections above

```ruby
# Standalone

Qo[name: /Rob/] === people_objects.first
# => true

# Case statement

case people_objects.first
when Qo[name: /Rob/] then "It's Rob!"
else 'Na, not them'
end
# => "It's Rob!"

# Select

people_objects.select(&Qo[name: /Rob/])
# => [Person(Robert, 22), Person(Roberta, 22)]
```

##### 3.2.4 - Predicate match present

```ruby
# Standalone

Qo[name: :empty?] === Person.new('', 22)
# => true

# Case statement

case Person.new('', nil)
when Qo[age: :nil?] then 'No age provided!'
else 'nope'
end
# => "No age provided!"

# Select

people_hashes.select(&Qo[age: :nil?])
# => []
```

### 4 - Right Hand Pattern Matching

This is where I start going a bit off into the weeds. We're going to try and get RHA style pattern matching in Ruby.

```ruby
Qo.match(['Robert', 22],
  Qo.m(:*, 20..99) { |n, a| "#{n} is an adult that is #{a} years old" },
  Qo.m(:*)
)
# => "Robert is an adult that is 22 years old"
```

```ruby
Qo.match(people_objects.first,
  Qo.m(name: :*, age: 20..99) { |person| "#{person.name} is an adult that is #{person.age} years old" },
  Qo.m(:*)
)
```

In this case it's trying to do a few things:

1. Iterate over every matcher until it finds a match
2. Execute its block function

If no block function is provided, it assumes an identity function (`-> v { v }`) instead. If no match is found, `nil` will be returned.

If an initial target is not furnished, the matcher will become a curried proc awaiting a target. In more simple terms it just wants a target to run against, so let's give it a few with map:

```ruby
name_longer_than_three = -> person { person.name.size > 3 }

people_objects.map(&Qo.match(
  Qo.m(name_longer_than_three) { |person|
    person.name = person.name[0..2]
    person
  },
  Qo.m(:*)
))

# => [Person(age: 22, name: "Rob"), Person(age: 22, name: "Rob"), Person(age: 42, name: "Foo"), Person(age: 17, name: "Bar")]
```

So we just truncated everyone's name that was longer than three characters.

### 6 - Helper functions

There are a few functions added for convenience, and it should be noted that because all Qo matchers respond to `===` that they can be used as helpers as well.

#### 6.1 - Dig

Dig is used to get in deep at a nested hash value. It takes a dot-path and a `===` respondent matcher:

```ruby
Qo.dig('a.b.c', Qo.or(1..5, 15..25)) === {a: {b: {c: 1}}}
# => true

Qo.dig('a.b.c', Qo.or(1..5, 15..25)) === {a: {b: {c: 20}}}
# => true
```

To be fair that means anything that can respond to `===`, including classes and other such things.

#### 6.2 - Count By

This ends up coming up a lot, especially around querying, so let's get a way to count by!

```ruby
Qo.count_by([1,2,3,2,2,2,1])

# => {
#   1 => 2,
#   2 => 4,
#   3 => 1
# }

Qo.count_by([1,2,3,2,2,2,1], &:even?)

# => {
#   false => 3,
#   true  => 4
# }
```

### 5 - Hacky Fun Time

These examples will grow over the next few weeks as I think of more fun things to do with Qo. PRs welcome if you find fun uses!

#### 5.1 - JSON and HTTP

> Note that Qo does not support deep querying of hashes (yet)

##### 5.1.1 - JSON Placeholder

Qo tries to be clever though, it assumes Symbol keys first and then String keys, so how about some JSON?:

```ruby
require 'json'
require 'net/http'

posts = JSON.parse(
  Net::HTTP.get(URI("https://jsonplaceholder.typicode.com/posts")), symbolize_names: true
)

users = JSON.parse(
  Net::HTTP.get(URI("https://jsonplaceholder.typicode.com/users")), symbolize_names: true
)

# Get all posts where the userId is 1.
posts.select(&Qo[userId: 1])

# Get users named Nicholas or have two names and an address somewhere with a zipcode
# that starts with 9 or 4.
#
# Qo matchers return a `===` respondant object, remember, so we can totally nest them.
users.select(&Qo.and(
  name: Qo.or(/^Nicholas/, /^\w+ \w+$/),
  address: {
    zipcode: Qo.or(/^9/, /^4/)
  }
))

# We could even use dig to get at some of the same information. This and the above will
# return the same results even.
users.select(&Qo.and(
  Qo.dig('address.zipcode', Qo.or(/^9/, /^4/)),
  name: Qo.or(/^Nicholas/, /^\w+ \w+$/)
))
```

Nifty!

##### Yield Self HTTP status matching

You can even use `#yield_self` to pipe values into a pattern matching block. In
this particular case it'll let you check against the type signatures of the
HTTP responses.

```ruby
def get_url(url)
  Net::HTTP.get_response(URI(url)).yield_self(&Qo.match(
    Qo.m(Net::HTTPSuccess) { |response| response.body.size },
    Qo.m(:*)               { |response| raise response.message }
  ))
end

get_url('https://github.com/baweaver/qo')
# => 142387
get_url('https://github.com/baweaver/qo/does_not_exist')
# => RuntimeError: Not Found
```

The difference between this and case? Well, the first is you can pass this to
`yield_self` for a more inline solution. The second is that any Qo matcher can
be used in there, including predicate and content checks on the body:

```ruby
Qo.m(Net::HTTPSuccess, body: /Qo/)
```

You could put as many checks as you want in there, or use different Qo matchers
nested to get even further in.

#### 5.2 - Opsy Stuff

##### 5.2.1 - NMap

What about NMap for our Opsy friends? Well, simulated, but still fun.

```ruby
hosts = (`nmap -oG - -sP 192.168.1.* 10.0.0.* | grep Host`).lines.map { |v| v.split[1..2] }
=> [["192.168.1.1", "(Router)"], ["192.168.1.2", "(My Computer)"], ["10.0.0.1", "(Gateway)"]]

hosts.select(&Qo[IPAddr.new('192.168.1.1/8')])
=> [["192.168.1.1", "(Router)"], ["192.168.1.2", "(My Computer)"]]
```

##### 5.2.2 - `df`

The nice thing about Unix style commands is that they use headers, which means CSV can get a hold of them for some good formatting. It's also smart enough to deal with space separators that may vary in length:

```ruby
rows = CSV.new(`df -h`, col_sep: " ", headers: true).read.map(&:to_h)

rows.map(&Qo.match(
  Qo.m(Avail: /Gi$/) { |row|
    "#{row['Filesystem']} mounted on #{row['Mounted']} [#{row['Avail']} / #{row['Size']}]"
  }
)).compact
# => ["/dev/***** mounted on / [186Gi / 466Gi]"]
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'qo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install qo

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/baweaver/qo. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Qo project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/baweaver/qo/blob/master/CODE_OF_CONDUCT.md).

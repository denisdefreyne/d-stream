# D★Stream

[![Gem version](http://img.shields.io/gem/v/d-stream.svg)](http://rubygems.org/gems/d-stream)
[![Build status](http://img.shields.io/travis/ddfreyne/d-stream.svg)](https://travis-ci.org/ddfreyne/d-stream)
[![Code Climate](http://img.shields.io/codeclimate/github/ddfreyne/d-stream.svg)](https://codeclimate.com/github/ddfreyne/d-stream)
[![Code Coverage](http://img.shields.io/codecov/c/github/ddfreyne/d-stream.svg)](https://codecov.io/github/ddfreyne/d-stream)

_D★Stream_ is a set of extensions for writing stream-processing code in Ruby.

**CAUTION:** D★Stream is work in progress, and pre-alpha quality.

## Examples

### Example 1: straightforward

The following example takes a sequence of events for a given ticket, and calculates the history for that ticket, using slowly changing dimensions:

```ruby
events =
  Enumerator.new do |y|
    y << { id: 40562348, at: Time.now - 400, status: 'new' }
    y << { id: 40564682, at: Time.now - 300, assignee_id: 2 }
    y << { id: 40565795, at: Time.now - 250, priority: 'high' }
    y << { id: 40569932, at: Time.now - 100, status: 'solved' }
  end.lazy

S = DStream

indices = (1..(1.0 / 0.0))

history =
  S.apply(
    events,

    # calculate new state
    S.scan({}, &:merge),

    # add `version`
    S.zip(indices),
    S.map { |(e, i)| e.merge(version: i) },

    # remove `id`
    S.map { |e| e.reject { |k, _v| k == :id } },

    # add `valid_to` and `valid_from`, and remove `at`
    S.with_next,
    S.map { |(a, b)| a.merge(valid_to: b ? b.fetch(:at) : nil) },
    S.map { |e| e.merge(valid_from: e.fetch(:at)) },
    S.map { |e| e.reject { |k, _v| k == :at } },

    # add `row_is_current`
    S.with_next,
    S.map { |(a, b)| a.merge(row_is_current: b.nil?) },
  )

history.each { |e| p e }
```

The output is as follows:

```
{
  :status=>"new",
  :valid_from=>2017-05-05 20:18:14 +0200,
  :valid_to=>2017-05-05 20:19:54 +0200,
  :version=>1,
  :row_is_current=>false
}
{
  :status=>"new",
  :assignee_id=>2,
  :valid_from=>2017-05-05 20:19:54 +0200,
  :valid_to=>2017-05-05 20:20:44 +0200,
  :version=>2,
  :row_is_current=>false
}
{
  :status=>"new",
  :assignee_id=>2,
  :priority=>"high",
  :valid_from=>2017-05-05 20:20:44 +0200,
  :valid_to=>2017-05-05 20:23:14 +0200,
  :version=>3,
  :row_is_current=>false
}
{
  :status=>"solved",
  :assignee_id=>2,
  :priority=>"high",
  :valid_from=>2017-05-05 20:23:14 +0200,
  :valid_to=>nil,
  :version=>4,
  :row_is_current=>true
}
```

### Example 2: better factored

This example is functionally identical to the one above, but uses `S.compose` in order to make the final process, `history_builder`, easier to understand.

```ruby
events =
  Enumerator.new do |y|
    y << { id: 40562348, at: Time.now - 400, status: 'new' }
    y << { id: 40564682, at: Time.now - 300, assignee_id: 2 }
    y << { id: 40565795, at: Time.now - 250, priority: 'high' }
    y << { id: 40569932, at: Time.now - 100, status: 'solved' }
  end.lazy

S = DStream

merge =
  S.scan({}, &:merge),

indices = (1..(1.0 / 0.0))
add_version =
  S.compose(
    S.zip(indices),
    S.map { |(e,i)| e.merge(version: i) },
  )

remove_id =
  S.map { |e| e.reject { |k, _v| k == :id } }

add_valid_dates =
  S.compose(
    S.with_next,
    S.map { |(a,b)| a.merge(valid_to: b ? b.fetch(:at) : nil) },
    S.map { |e| e.merge(valid_from: e.fetch(:at)) },
    S.map { |e| e.reject { |k, _v| k == :at } },
  )

add_row_is_current =
  S.compose(
    S.with_next,
    S.map { |(a,b)| a.merge(row_is_current: b.nil?) },
  )

history_builder =
  S.compose(
    merge,
    add_version,
    remove_id,
    add_valid_dates,
    add_row_is_current,
  )

history = S.apply(events, history_builder)

history.each { |h| p h }
```

## API

The following functions create individual processors:

* `map(&block)`
* `buffer(size)`
* `with_next`
* `select(&block)`
* `reduce(&block)`
* `scan(init, &block)`
* `flatten2`
* `take(n)`
* `zip(other)`

To apply one or more processors to a stream, use `.apply`:

```ruby
S = DStream

stream = ['hi']

S.apply(stream, S.map(&:upcase)).to_a
# => ["HI"]
```

To combine one or more processors, use `.compose`:

```ruby
S = DStream

stream = ['hi']

processor = S.compose(
  S.map(&:upcase),
  S.map(&:reverse),
)

S.apply(stream, processor).to_a
# => ["IH"]
```

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

history_builder =
  S.compose(
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

history = history_builder.apply(events)
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

history = history_builder.apply(events)
history.each { |h| p h }
```

## API

The following functions create individual processors:

* `map(&block)` (similar to `Enumerable#map`)

    ```ruby
    S.map(&:odd?).apply(1..5).to_a
    # => [true, false, true, false, true]
    ```

* `select(&block)` (similar to `Enumerable#select`)

    ```ruby
    S.select(&:odd?).apply(1..5).to_a
    # => [1, 3, 5]
    ```

* `reduce(&block)` (similar to `Enumerable#reduce`)

    ```ruby
    S.reduce(&:+).apply(1..5)
    # => 15
    ```

* `take(n)` (similar to `Enumerable#take`)

    ```ruby
    S.take(3).apply(1..10).to_a
    # => [1, 2, 3]
    ```

* `zip(other)` (similar to `Enumerable#zip`):

    ```ruby
    S.zip((10..13)).apply(1..3).to_a
    # => [[1, 10], [2, 11], [3, 12]]
    ```

* `buffer(size)` yields each stream element, but keeps an internal buffer of not-yet-yielded stream elements. This is useful when reading from a slow and bursty data source, such as a paginated HTTP API.

* `with_next` yields an array containing the stream element and the next stream element, or nil when the end of the stream is reached:

    ```ruby
    S.with_next.apply(1..5).to_a
    # => [[1, 2], [2, 3], [3, 4], [4, 5], [5, nil]]
    ```

* `scan(init, &block)` is similar to `reduce`, but rather than returning a single aggregated value, returns all intermediate aggregated values:

    ```ruby
    S.scan(0, &:+).apply(1..5).to_a
    # => [1, 3, 6, 10, 15]
    ```

* `flatten2` yields the stream element if it is not an array, otherwise yields the stream element array’s contents:

    ```ruby
    S.compose(S.with_next, S.flatten2).apply(1..5).to_a
    # => [1, 2, 2, 3, 3, 4, 4, 5, 5, nil]
    ```

To apply a processor to a stream, use `#apply`:

```ruby
S = DStream

stream = ['hi']

S.map(&:upcase).apply(stream).to_a
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

processor.apply(stream).to_a
# => ["IH"]
```

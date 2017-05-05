require 'd-stream'

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

    # add version column
    S.zip(indices),
    S.map { |(e,i)| e.merge(version: i) },

    # remove id
    S.map { |e| e.reject { |k, _v| k == :id } },

    # add valid_to and valid_from, and remove at
    S.with_next,
    S.map { |(a,b)| a.merge(valid_to: b ? b.fetch(:at) : nil) },
    S.map { |e| e.merge(valid_from: e.fetch(:at)) },
    S.map { |e| e.reject { |k, _v| k == :at } },

    # add row_is_current
    S.with_next,
    S.map { |(a,b)| a.merge(row_is_current: b.nil?) },
  )

history.each { |h| p h }

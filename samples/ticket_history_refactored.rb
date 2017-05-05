require 'd-stream'

events =
  Enumerator.new do |y|
    y << { id: 40562348, at: Time.now - 400, status: 'new' }
    y << { id: 40564682, at: Time.now - 300, assignee_id: 2 }
    y << { id: 40565795, at: Time.now - 250, priority: 'high' }
    y << { id: 40569932, at: Time.now - 100, status: 'solved' }
  end.lazy

S = DStream

merge =
  S.scan({}, &:merge)

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

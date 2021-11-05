# frozen_string_literal: true

require 'd-stream'

events =
  Enumerator.new do |y|
    y << { id: 40_562_348, at: Time.now - 400, status: 'new' }
    y << { id: 40_564_682, at: Time.now - 300, assignee_id: 2 }
    y << { id: 40_565_795, at: Time.now - 250, priority: 'high' }
    y << { id: 40_569_932, at: Time.now - 100, status: 'solved' }
  end.lazy

S = DStream

indices = (1..(1.0 / 0.0))

history_builder =
  S.compose(
    # calculate new state
    S.scan({}, &:merge),
    # add version column
    S.zip(indices),
    S.map { |(e, i)| e.merge(version: i) },
    # remove id
    S.map { |e| e.except(:id) },
    # add valid_to and valid_from, and remove at
    S.with_next,
    S.map { |(a, b)| a.merge(valid_to: b ? b.fetch(:at) : nil) },
    S.map { |e| e.merge(valid_from: e.fetch(:at)) },
    S.map { |e| e.except(:at) },
    # add row_is_current
    S.with_next,
    S.map { |(a, b)| a.merge(row_is_current: b.nil?) }
  )

history = history_builder.call(events)

history.each { |h| p h }

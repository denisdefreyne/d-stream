# frozen_string_literal: true

require 'd-stream'

S = DStream

stream = ['hi']

processor = S.compose(
  S.map(&:upcase),
  S.map(&:reverse)
)

p processor.call(stream).to_a

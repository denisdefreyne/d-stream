require 'd-stream'

S = DStream

stream = ['hi']

processor = S.compose(
  S.map(&:upcase),
  S.map(&:reverse)
)

p processor.apply(stream).to_a

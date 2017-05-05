require 'd-stream'

S = DStream

stream = ['hi']

processor = S.compose(
  S.map(&:upcase),
  S.map(&:reverse)
)

p S.apply(stream, processor).to_a

require 'd-stream'

S = DStream

stream = ['hi']

p S.apply(stream, S.map(&:upcase)).to_a

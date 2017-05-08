require 'd-stream'

S = DStream

stream = ['hi']

p S.map(&:upcase).apply(stream).to_a

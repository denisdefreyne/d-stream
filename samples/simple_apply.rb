# frozen_string_literal: true

require 'd-stream'

S = DStream

stream = ['hi']

p S.map(&:upcase).call(stream).to_a

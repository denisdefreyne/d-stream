# frozen_string_literal: true

module DStream
  def self.map(&block)
    Transformers::SimpleB.new(:map, &block)
  end

  def self.buffer(size)
    Transformers::Buffer.new(size)
  end

  def self.with_next
    Transformers::WithNext.new
  end

  def self.select(&block)
    Transformers::SimpleB.new(:select, &block)
  end

  def self.reduce(&block)
    Transformers::SimpleB.new(:reduce, &block)
  end

  def self.scan(init, &block)
    Transformers::Scan.new(init, &block)
  end

  def self.flatten2
    Transformers::Flatten2.new
  end

  def self.take(n)
    Transformers::Simple1.new(:take, n)
  end

  def self.chunk(&block)
    Transformers::SimpleB.new(:chunk, &block)
  end

  def self.zip(other)
    Transformers::Zip.new(other)
  end

  def self.compose(*procs)
    Transformers::Compose.new(procs)
  end
end

require_relative 'd-stream/transformers'

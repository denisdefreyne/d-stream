module DStream
  class Abstract
    def inspect
      "<#{self.class}>"
    end
  end

  class SimpleB < Abstract
    def initialize(sym, &block)
      @sym = sym
      @block = block
    end

    def inspect
      "<#{self.class} #{@sym.inspect}>"
    end

    def apply(s)
      s.to_enum.lazy.__send__(@sym, &@block)
    end
  end

  class Simple1 < Abstract
    def initialize(sym, arg)
      @sym = sym
      @arg = arg
    end

    def apply(s)
      s.to_enum.lazy.__send__(@sym, @arg)
    end
  end

  class Scan < Abstract
    def initialize(init, &block)
      @init = init
      @block = block
    end

    def apply(s)
      Enumerator.new do |y|
        acc = @init

        s.each do |e|
          acc = @block.call(acc, e)
          y << acc
        end
      end.lazy
    end
  end

  class Trickle < Abstract
    def initialize(rate)
      @rate = rate
    end

    def apply(s)
      q = SizedQueue.new(1)
      stop = Object.new

      t =
        Thread.new do
          Thread.current.abort_on_exception = true
          s.each do |e|
            q << e
            sleep(1.0 / @rate)
          end
          q << stop
        end

      Enumerator.new do |y|
        loop do
          e = q.pop
          break if stop.equal?(e)
          y << e
        end
        t.join
      end.lazy
    end
  end

  class Burst < Abstract
    def initialize(delay, size)
      @delay = delay
      @size = size
    end

    def apply(s)
      q = SizedQueue.new(1)
      stop = Object.new

      t =
        Thread.new do
          Thread.current.abort_on_exception = true
          i = 0
          s.each do |e|
            sleep(@delay) if (i % @size).zero?
            q << e
            i += 1
          end
          q << stop
        end

      Enumerator.new do |y|
        loop do
          e = q.pop
          break if stop.equal?(e)
          y << e
        end
        t.join
      end.lazy
    end
  end

  class Buffer < Abstract
    def initialize(size)
      @size = size
    end

    def apply(s)
      q = SizedQueue.new(@size)
      stop = Object.new

      t =
        Thread.new do
          Thread.current.abort_on_exception = true
          s.each { |e| q << e }
          q << stop
        end

      Enumerator.new do |y|
        loop do
          e = q.pop
          break if stop.equal?(e)
          y << e
        end
        t.join
      end.lazy
    end
  end

  class WithNext < Abstract
    def apply(s)
      Enumerator.new do |y|
        prev = nil
        have_prev = false

        s.each do |e|
          if have_prev
            y << [prev, e]
          else
            have_prev = true
          end
          prev = e
        end
        y << [prev, nil]
      end.lazy
    end
  end

  class Flatten2 < Abstract
    def apply(s)
      Enumerator.new do |y|
        s.each do |es|
          es.each { |e| y << e }
        end
      end.lazy
    end
  end

  class Zip < Abstract
    def initialize(other)
      @other = other
    end

    def inspect
      "<DStream::Zip #{@other.inspect}>"
    end

    def apply(s)
      Enumerator.new do |y|
        s.lazy.zip(@other).each do |e, i|
          y << [e, i]
        end
      end.lazy
    end
  end

  class Compose < Abstract
    def initialize(procs)
      @procs = procs
    end

    def inspect
      "<DStream::Compose #{@procs.map(&:inspect).join(' -> ')}>"
    end

    def apply(s)
      @procs.inject(s) { |acc, pr| pr.apply(acc) }
    end
  end

  def self.map(&block)
    SimpleB.new(:map, &block)
  end

  def self.trickle(rate)
    Trickle.new(rate)
  end

  def self.burst(rate, size)
    Burst.new(rate, size)
  end

  def self.buffer(size)
    Buffer.new(size)
  end

  def self.with_next
    WithNext.new
  end

  def self.select(&block)
    SimpleB.new(:select, &block)
  end

  def self.reduce(&block)
    SimpleB.new(:reduce, &block)
  end

  def self.scan(init, &block)
    Scan.new(init, &block)
  end

  def self.flatten2
    Flatten2.new
  end

  def self.take(n)
    Simple1.new(:take, n)
  end

  def self.chunk_by
    # …
  end

  def self.zip(other)
    Zip.new(other)
  end

  def self.compose(*procs)
    Compose.new(procs)
  end

  def self.apply(s, *procs)
    compose(*procs).apply(s)
  end
end

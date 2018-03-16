# frozen_string_literal: true

module DStream
  module Transformers
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

      def call(s)
        s.to_enum.lazy.__send__(@sym, &@block)
      end
    end

    class Simple1 < Abstract
      def initialize(sym, arg)
        @sym = sym
        @arg = arg
      end

      def call(s)
        s.to_enum.lazy.__send__(@sym, @arg)
      end
    end

    class Scan < Abstract
      def initialize(init, &block)
        @init = init
        @block = block
      end

      def call(s)
        Enumerator.new do |y|
          acc = @init

          s.each do |e|
            acc = @block.call(acc, e)
            y << acc
          end
        end.lazy
      end
    end

    class Buffer < Abstract
      def initialize(size)
        @buf = DDBuffer.new(size)
      end

      def call(s)
        @buf.call(s)
      end
    end

    class WithNext < Abstract
      def call(s)
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
      def call(s)
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

      def call(s)
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

      def call(s)
        @procs.inject(s) { |acc, pr| pr.call(acc) }
      end
    end
  end
end

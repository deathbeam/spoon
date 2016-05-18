module Spoon
  module Util
    class Namespace
      def initialize
        @map = []
      end

      def add
        @map.push Hash.new
      end

      def push(key, value = true)
        unless has?(key)
          get[key] = value
          true
        else
          false
        end
      end

      def pop
        @map.pop
      end

      def get
        @map.last
      end

      def has?(key)
        @map.each do |namespace|
          return true if namespace.key?(key)
        end

        false
      end
    end
  end
end

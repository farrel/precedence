module Precedence
  module Utilities #:nodoc:
    # A modified Hash that has all keys as strings
    class ActivityHash < Hash #:nodoc:
      def initialize(startActivity, finishActivity)
        super(nil)
        @start = startActivity
        @finish = finishActivity
      end

      def[]=(ref, value)
        if (ref != @start.reference) && (ref != @finish.reference)
          super(ref.to_s, value)
        end
      end

      def[](ref)
        if ref.to_s == @start.reference
          @start
        elsif ref.to_s == @finish.reference
          @finish
        else
          super(ref.to_s)
        end
      end
    end

    # A modified Hash that has all keys as strings and all values as floats
    class ResourceHash < Hash #:nodoc:
      def initialze
        super(0.0)
      end

      def [](resource)
        super(resource.to_s)
      end

      def []=(resource, value)
        super(resource.to_s, value.to_f)
      end
    end
  end
end

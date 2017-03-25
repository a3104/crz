include CRZ

module CRZ::Containers
  adt_class Option(A), {
    Some(A), None,
  },
    abstract class ADTOption(A)
      include Monad(A)

      def to_s
        Option.match self, {
          [Some, x] => "Some(#{x})",
          [None]    => "None",
        }
      end

      def self.pure(value : T) : Option(T) forall T
        Option::Some.new(value)
      end

      def unwrap : A
        Option.match self, {
          [Some, x] => x,
          [None]    => raise Exception.new("Tried to unwrap Option::None value"),
        }
      end

      def has_value : Bool
        Option.match self, {
          [Some, _] => true,
          [_]       => false,
        }
      end

      def bind(&block : A -> Option(B)) : Option(B) forall B
        # Option.match self, {
        #   [Some, x] => (block.call x),
        #   [None]    => Option::None(B).new
        # }
        if (self.is_a? Option::Some(A))
          yield self.value0
        elsif (self.is_a? Option::None(A))
          Option::None(B).new
        else
          raise Exception.new("Option#bind called for unknown subtype of Option #{typeof(self)}")
        end
      end
    end
end

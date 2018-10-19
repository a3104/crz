module CRZ::Containers
  alias Ok = Result::Ok
  alias Err = Result::Err
  adt Result(T, E),
    Ok(T),
    Err(E) do
    include Monad(T)

    def self.of(value : T) : Result(T, E)
      Result::Ok(T, E).new value
    end

    def bind(&block : T -> Result(U, E)) : Result(U, E) forall U
      Result.match self, {
        [Ok, x]  => (block.call x),
        [Err, e] => Result::Err(U, E).new e,
      }
    end

    def map(&block : T -> U) : Result(U, E) forall U
      Result.match self, {
        [Ok, x]  => (Result::Ok(U, E).new (block.call x)),
        [Err, e] => Result::Err(U, E).new e,
      }
    end

    def unwrap : T
      Result.match self, {
        [Ok, x]  => x,
        [Err, e] => raise Exception.new("Tried to unwrap Result::Err value"),
      }
    end

    def unwrap_error : E
      Result.match self, {
        [Err, e] => e,
        [Ok, x]  => raise Exception.new("Tried to unwrap_error Result::Ok value"),

      }
    end

    def unwrap_or_error
      Result.match self, {
        [Ok, x]  => x,
        [Err, e] => e,
      }
    end

    def flatten : T
      unwrap
    end

    def flat_map(&block : T -> Result(U, E)) : Result(U, E) forall U
      bind(block)
    end

    def unwrap_or(default)
      Result.match self, {
        [Ok, x]  => x,
        [Err, e] => default,
      }
    end

    def get_or_else(default)
      unwrap_or(default)
    end

    def to_option
      Result.match self, {
        [Ok, x]  => Option::Some.of(x),
        [Err, e] => Option::None(T).new,
      }
    end

    def has_value : Bool
      Result.match self, {
        [Ok, x] => true,
        [_]     => false,
      }
    end
  end
end

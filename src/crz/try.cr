module CRZ::Containers
  adt Try(A), Success(A), Failure do
    include Monad(A)

    @error : Exception = Exception.new
    property :error

    def self.try(&block : -> A) : Try(A) forall A
      begin
        Try::Success(A).new(block.call)
      rescue err
        e = Try::Failure(A).new
        e.error = err
        e
      end
    end

    def self.of(value : A) : Try(A) forall A
      Try::Success(A).new(value)
    end

    def map(&block : A -> U) : Try(U) forall U
      if self.is_a?(Try::Failure)
        self
      else
        begin
          Try.of(block.call(self.get))
        rescue e
          error = Try::Failure(U).new
          error.error = e
          error
        end
      end
    end

    def flat_map(&block : A -> Try(B)) : Try(B) forall B
      bind(block)
    end

    def bind(&block : A -> Try(B)) : Try(B) forall B
      self.is_a?(Try::Success) ? block.call(self.value0) : self
    end

    def unwrap : A
      self.is_a?(Try::Success) ? self.value0 : raise self.error
    end

    def flatten : A
      unwrap
    end

    def get : A
      unwrap
    end

    def has_value : Bool
      self.is_a?(Try::Success) ? true : false
    end

    def to_s
      self.is_a?(Try::Success) ? "Try::Success(#{value0})" : "Try::Failure"
    end

    def unwrap_or(default : A) : A
      self.is_a?(Try::Success) ? self.get : default
    end

    def unwrap_or_else(default : A) : A
      unwrap_or(default)
    end

    def get_or_else(default : A) : A
      unwrap_or(default)
    end

    def get_option : Option(A)
      self.is_a?(Try::Success) ? Option::Some(A).new(self.value0) : Option::None(A).new
    end

    def get_result
      self.is_a?(Try::Success) ? Result::Ok(A, Excception).new(self.value0) : Result::Err(A, Exception).new(self.error)
    end

    def get_result_with_err(error)
      self.is_a?(Try::Success) ? Result::Ok(A, typeof(error)).new(self.value0) : Result::Err(A, typeof(error)).new(error)
    end
  end
end

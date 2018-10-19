require "./*"
include CRZ

class TimeoutException < Exception
end

module CRZ::Containers
  adt Future(A), Success(A), Processing(A), Failure do
    include Monad(A)

    @error : Exception = Exception.new
    @channel = Channel(Int32 | Exception).new
    @is_completed = false
    @is_error = false

    property :channel, :is_completed
    property :error, :is_error

    # Set dummy to an instance of type A.
    # The value can be anything. It needs to be set in order to pass through the compiler.
    # If anyone has a good idea please let me know.
    def self.spawn(dummy : A, timeout = 0, &block : -> A) : Future(A) forall A
      c = Channel(Int32 | Exception).new
      f = Future::Processing(A).new(dummy)
      if timeout > 0
        spawn do
          sleep(timeout)
          f.error = TimeoutException.new
          f.is_error = true
          f.is_completed = true
          c.close
        end
      end

      f.channel = c
      s = spawn do
        begin
          f.is_completed = false
          result = block.call
          f.value0 = result
          f.is_completed = true
          c.send(1)
        rescue err
          f.error = err
          f.is_error = true
          f.is_completed = true
          c.send(err)
        end
      end
      f
    end

    def self.of(value : A) : Future(A) forall A
      f = Future::Success(A).new(value)
      f.is_completed = true
      f
    end

    def flat_map(&block : A -> Future(B)) : Future(B) forall B
      bind(&block)
    end

    def bind(&block : A -> Future(B)) : Future(B) forall B
      begin
        channel.receive if is_completed == false && self.is_a?(Future::Processing)
      rescue e
        @error = e
        @is_error = true
      end

      if self.is_a?(Future::Processing)
        @is_error == false ? block.call(self.value0) : (f = Future::Failure(A).new; f.error = @error; f)
      elsif self.is_a?(Future::Success)
        @is_error == false ? block.call(self.value0) : (f = Future::Failure(A).new; f.error = @error; f)
      else
        self
      end
    end

    def map(&block : A -> U) : Future(U) forall U
      me = bind { |x| Future.of(x) }

      if me.is_error
        me
      elsif me.is_a?(Future::Failure)
        me
      else
        begin
          if me.is_a?(Future::Success) || me.is_a?(Future::Processing)
            block.call(me.value0)
            Future.of(block.call(me.value0))
          else
            me
          end
        rescue e
          f = Future::Failure(U).new
          f.error = e
          f.is_completed = true
          f
        end
      end
    end

    def map_future(default : U, &block : A -> U) : Future(U) forall U
      if self.is_a?(Future::Failure) || @is_error
        self
      elsif @is_completed
        me = self.bind { |x| Future.of(x) }
        if self.is_a?(Future::Success) && me.is_error == false
          begin
            block.call(self.value0)
          rescue
            Future::Failure(U).new
          end
        else
          Future::Failure(U).new
        end
      else
        Future.spawn(default) {
          me = bind { |x| Future.of(x) }
          block.call(self.value0)
        }
      end
    end

    def unwrap : A
      r = bind { |x| Future::Success(A).new(x) }
      if r.is_a?(Future::Success)
        r.value0
      elsif r.is_a?(Future::Processing)
        r.value0
      else
        raise r.error
      end
    end

    def flatten : A
      unwrap
    end

    def get : A
      unwrap
    end

    def get_or_else(default : A) : A
      bind { |x| Future::Success.new(0) }

      (self.is_a?(Future::Success) || self.is_a?(Future::Processing) && self.is_error == false) ? self.value0 : default
    end

    def get_option : Option(A)
      bind { |x| Future::Success.new(0) }

      (self.is_a?(Future::Success) || self.is_a?(Future::Processing) && self.is_error == false) ? Option::Some.new(self.value0) : Option::None(A).new
    end

    def get_result
      bind { |x| Future::Success.new(0) }

      (self.is_a?(Future::Success) || self.is_a?(Future::Processing) && self.is_error == false) ? Result::Ok(A, Excception).new(self.value0) : Result::Err(A, Exception).new(self.error)
    end

    def get_result_with_err(error)
      bind { |x| Future::Success.new(0) }

      (self.is_a?(Future::Success) || self.is_a?(Future::Processing) && self.is_error == false) ? Result::Ok(A, typeof(error)).new(self.value0) : Result::Err(A, typeof(error)).new(error)
    end

    def has_value
      bind { |x| Future::Success.new(0) }

      self.is_a?(Future::Failure) == false && is_error == false ? true : false
    end
  end
end

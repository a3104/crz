require "spec"
describe Option do
  it "creates Option::Some from constructor" do
    o = Option::Some.new 42
    o.value0.should eq 42
    typeof(o).should eq Option::Some(Int32)
    (o.responds_to? :map).should eq true
    (o.responds_to? :bind).should eq true
    (o.responds_to? :ap).should eq true
    (o.responds_to? :>>).should eq true
    (o.responds_to? :<<).should eq true
    (o.responds_to? :>=).should eq true
    (o.responds_to? :*).should eq true
  end

  it "creates Option::None from constructor" do
    o = Option::None(Int32).new
    typeof(o).should eq Option::None(Int32)
    (o.responds_to? :map).should eq true
    (o.responds_to? :bind).should eq true
    (o.responds_to? :ap).should eq true
    (o.responds_to? :>>).should eq true
    (o.responds_to? :<<).should eq true
    (o.responds_to? :>=).should eq true
    (o.responds_to? :*).should eq true
  end

  it "implements pure method" do
    o = Option.pure(2)
    typeof(o).should eq Option::Some(Int32)
  end

  it "works as a functor" do
    some = Option::Some.new 34
    mapped = some.map do |x|
      x.should eq 34
      x + 1
    end
    Option.match mapped, {
      [Some, x] => (x.should eq 35),
      _         => (1.should eq 2),
    }

    string_option = mapped.map &.to_s
    Option.match string_option, {
      [Some, x] => (x.should eq "35"),
      _         => (1.should eq 2),
    }

    none = Option::None(Int32).new
    mapped = none.map do |x|
      1.should eq 2
      x + 3
    end

    Option.match mapped, {
      [Some, x] => (1.should eq 2),
      [None]    => (1.should eq 1),
    }
  end

  it "works as an applicative" do
    someF = Option.pure ->(x : Int32) {
      x + 1
    }
    some12 = Option.pure(12)
    some12.unwrap.should eq 12

    none = Option::None(Int32).new
    applied = none.ap(someF)
    applied.has_value.should eq false

    noop = Option::None(Int32 -> Int32).new
    some12.ap(noop).has_value.should eq false

    f = ->(x : Int32, y : Int32) {
      x + y
    }
  end
end

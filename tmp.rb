def get_binding
  a = 2
  b = 3
  binding
end

code = "a+b"
p eval(code, get_binding)

class Quote
  def initialize
    @str = "The quick brown fox"
  end
end
def create_method_using_a_closure
  str2 = "jumps over the lazy dog."
  lambda do
    puts "#{@str} #{str2}"
  end
end
Quote.send(:define_method, :display, create_method_using_a_closure)
Quote.new.display

one = ['a', 'b', 'c']
two = ['A', 'B', 'C']
three=['m', 'n', 'k', 'h']
four=%w(x y )

arrays = [one,two,three,four]
keys = %w{one two three four}
klass = Struct.new(*keys.map(&:to_sym))

objects = arrays.reduce(&:zip).map{|tup| klass.new(*tup.flatten)}

def hash_from_arr(arr)
  arr.reduce({}) do |res, element|
    i = res.size
    res.merge!(i=>element)
  end
end
p hash_from_arr(objects)

require 'ostruct'
def list
  @list ||= [
      {name:'tom', format: :a},
      {name:'bob', format: :b},
      {name:'dav', format: :c}
  ].map{|v| OpenStruct.new(v)}
end
def rule
  @rule ||= {a:'xxx', b:'yyy', c:'zzz'}
end
def parse_format(format)
  rule[format]
end
def info_from_item(item)
  {item.name => parse_format(item.format)}
end

def hello
  list.map(&method(:info_from_item)).reduce({},&:merge)
end
p hello

module Enumerable
  def my_inject(acc=nil, meth=nil, &blk)
    meth,acc = [acc,nil] unless blk || meth
    raise "shouldn't provide both method_name and block" if meth && blk
    meth ||= blk
    raise "should provide method_name or block" unless meth && meth.respond_to?(:to_proc)

    acc,all = acc ? [acc, self] : [first, drop(1)]
    all.safe_inject(acc, &meth.to_proc)
  end
  def safe_inject(acc)
    each {|v| acc = yield acc,v}
    acc
  end
end
p (1..10).my_inject(:+)
p (1..10).my_inject(&:+)
p (1..10).my_inject(10, :+)
p (1..10).my_inject(10, &:+)
# p (1..2).my_inject(0, :+, &:*)
# p (1..10).my_inject(0)

module MyFeatures
  module ClassMethods
    def say_hello
      "Hello"
    end
  end
  def self.included(base)
    base.extend(ClassMethods)
  end
  def say_hello
    "Hello from #{self}"
  end
end

class A
  include MyFeatures
end
p A.new.say_hello
p A.say_hello


class Lazy
  class Filtered
  end
  def initialize(lst, &trans)
    @lst = lst.to_enum
    @trans = trans || proc{|v| v}
  end
  def first(n)
    n.times.reduce([]) do |res|
      begin
        v = self.next
        res << v
      rescue StopIteration
        break res
      end
    end
  end
  def next
    while true
      res = @trans[@lst.next]
      return res if res != Filtered
    end
  end
  def drop(n)
    n.times{self.next}
    self
  end
  def map(&blk)
    self.class.new(self, &blk)
  end
  def select(&blk)
    self.class.new(self){|v| blk[v] ? v : Filtered }
  end
  def to_enum
    @lst.to_enum
  end
end

class LazyEx
  def initialize(coll, &trans)
    @coll = coll
    @trans = trans || proc{|c,&b| c.each(&b)}
  end
  def first(n)
    take(n).to_a
  end
  def map(&blk)
    create do |c,&b|
      @trans.call(c){|e| b[blk[e]]}
    end
  end
  def select(&blk)
    create do |c,&b|
      @trans.call(c){|e| b[e] if blk[e]}
    end
  end
  def reject(&blk)
    select{|e| !blk[e]}
  end
  def drop(n)
    count = 0
    create do |c, &b|
      @trans.call(c) do |e|
        b[e] unless count<n
        count+=1
      end
    end
  end
  def take(n)
    count = 0
    create do |c, &b|
      @trans.call(c) do |e|
        count<n ? b[e] : break
        count+=1
      end
    end
  end
  def to_a
    res = []
    @trans.call(@coll) {|e| res<<e}
    res
  end

  private
  UNIT = proc{|e| e}
  def create(&blk)
    self.class.new(@coll,&blk)
  end
end

class LazyEE
  def initialize(coll, &trans)
    @coll = coll
    @trans = trans || proc{|c,&b| c.each(&b)}
  end

  def map(&blk)
    create do |c,&b|
      @trans.call(c){|e| b[blk[e]]}
    end
  end

  def select(&blk)
    create do |c,&b|
      @trans.call(c){|e| b[e] if blk[e]}
    end
  end

  def reject(&blk)
    select{|e| !blk[e]}
  end

  def drop(n)
    count = 0
    create do |c, &b|
      @trans.call(c) do |e|
        b[e] unless count<n
        count+=1
      end
    end
  end

  def take(n)
    res= []
    @trans.call(@coll) do |e|
      res.size<n ? res<<e : (return res)
    end
    res
  end

  alias_method :first, :take

  private
  def create(&blk)
    self.class.new(@coll,&blk)
  end
end
module Enumerable
  def my_lazy; lazy_type.new(self) end
  private
  def lazy_type
    LazyEE
    # LazyEx
    # Lazy
  end
end

x=(1...Float::INFINITY).my_lazy.map{|i| i*i}
p x.first(10)
p x.select(&:odd?).first(10)
p x.select(&:odd?).take(20).drop(2).first(10)

p ([1]*10).my_lazy.map{|i| i*i}.select(&:odd?).first(20)
p (1..10).my_lazy.map{|i| i*i}.reject(&:odd?).drop(2).first(20)
p (1..10).my_lazy.map{|i| i*i}.select(&:odd?).drop(2).first(20)
p (1..10).my_lazy.map{|i| i*i}.select(&:odd?).drop(2).map{nil}.map{1}.first(20)

p (1...Float::INFINITY).my_lazy.map{|i| i*i}.select{|i| i.to_s.reverse == i.to_s}.first(20)

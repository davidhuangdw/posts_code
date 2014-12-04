
# Ruby tips: patch on singleton_class

###问题
如何实现以下stub方法:
``` ruby
user = User.new
user.login?          #=> false

user.stub(:login?){ 'totally tubbed' }
user.login?          #=> 'totally stubbed'

User.new.login?      #=> false
``` 

###分析
不能直接patch在当前对象的类上，需要patch在当前对象的singleton_class上:
``` ruby
module Stubber
  extend self
  def mystub(method, to:nil, &blk)
    singleton = class << to||self; self end
    singleton.send(:define_method, method, &blk)        # define_method is private for singleton_class: use 'send' to bypass
  end
end
```
注意:
1. 可以用`class<<obj; self end `取到singleton_class
2. singleton_class的`define_method`是私有的，得用`.send(:define_method,*args)`

测试代码:
``` ruby
require_relative '../stubber'
require 'ostruct'

shared_examples_for 'stubbed' do
  it "should stub obj" do
    expect(after_stub.name).to eq 'stub'
    expect(other_obj.name).not_to eq 'stub'
  end
end

describe Stubber do
  let(:obj) {OpenStruct.new(name:'obj')}
  let(:other_obj) {OpenStruct.new(name:'obj')}
  let(:after_stub) do
    Stubber.mystub(:name, to:obj){ 'stub'}
    obj
  end
  it_behaves_like 'stubbed'

  context "when include Stubber in a class" do
    let(:foo_class) do
      Class.new do
        include Stubber
        def name; 'foo' end
      end
    end
    let(:obj) {foo_class.new}
    let(:other_obj) {foo_class.new}
    let(:after_stub) do
      obj.mystub(:name){'stub'}
      obj
    end
    it_behaves_like 'stubbed'
  end
end
```

# FizzBuzz

### 问题
你是一名体育老师，在某次课距离下课还有五分钟时，你决定搞一个游戏。此时有100名学生在上课。游戏的规则是：

1. 你首先说出三个不同的特殊数，要求必须是个位数，比如3、5、7。
2. 让所有学生拍成一队，然后按顺序报数。
3. 学生报数时，如果所报数字是第一个特殊数（3）的倍数，那么不能说该数字，而要说Fizz；如果所报数字是第二个特殊数（5）的倍数，那么要说Buzz；如果所报数字是第三个特殊数（7）的倍数，那么要说Whizz。
4. 学生报数时，如果所报数字同时是两个特殊数的倍数情况下，也要特殊处理，比如第一个特殊数和第二个特殊数的倍数，那么不能说该数字，而是要说FizzBuzz, 以此类推。如果同时是三个特殊数的倍数，那么要说FizzBuzzWhizz。
5. 学生报数时，如果所报数字包含了第一个特殊数，那么也不能说该数字，而是要说相应的单词，比如本例中第一个特殊数是3，那么要报13的同学应该说Fizz。如果数字中包含了第一个特殊数，那么忽略规则3和规则4，比如要报35的同学只报Fizz，不报BuzzWhizz。

### 分析
这个问题感觉是考察如何decouple和代码可读性。
为了允许用户增加和改变规则, 于是很直观地想到了这样：
```ruby
game.add_rule {..specifications..}
game.add_rule {..specifications..}
game.report(number)
```
扩充：
```ruby
class Game
  attr_accessor :result, :value
  def initialize
    @rules=[]
    yield self if block_given?
  end

  def add_rule(&blk)
    @rules << blk
  end

  def report(value)
    reset(value)
    @rules.each do |rule|
      @stopped ? break : instance_eval(&rule)
    end
    @result
  end

  private
  def stop_with(word)
    @stopped = true
    @result=word
  end
  def append(word)
    @result||=""
    @result<<word
  end
  def default_with(v); @result||=v end
  def reset(value)
    @value = value
    @result = nil
    @stopped = false
  end
end

def create_fizzbuzz
  Game.new do |r|
    r.add_rule{ stop_with('Fizz') if(value.to_s.include?('3')) }
    r.add_rule do
      append('Fizz') if(value%3==0)
      append('Buzz') if(value%5==0)
      append('Whizz') if(value%7==0)
      default_with(value)
    end
  end
end

def run(game, num=100)
  (1..num).map{|i| game.report(i)}
end

# puts run
```
测试代码:
```ruby
require_relative '../fizzbuzz'

describe Game do
  let(:game) {create_fizzbuzz}
  let(:result) do
    %W{
1
2
Fizz
4
Buzz
Fizz
Whizz
8
Fizz
Buzz
11
Fizz
Fizz
Whizz
FizzBuzz
16
17
Fizz
19
Buzz
    }
  end
  it "should follow game rules" do
    expect(run(game,20).map(&:to_s)).to eq result
  end
end
```

# 求两个有序数组的第k大值
**问题**：100个运动员站成两排，每排已经按从高到低顺序排好，教练想找出身高排40位的队员，请问最少需要几次比较？（限制每次只能两个队员比身高）
**分析**: 也就是从两个有序数组中，找第k大的值。归并比较的话需要O(k)，所以这题希望找复杂更小的答案，比如O(logK)之类的。写个test先:
```ruby
describe KthOfTwoSorted do
  let(:result) {subject.kth_of_two_sorted(n-1,x,y)}
  context "simple example" do
    let(:x) {[1,3,5,7,9]}
    let(:y) {[2,4,6,8,10]}
    let(:n) {8}
    let(:ans) {8}
    it "should find kth" do
      expect(result).to eq ans
    end
  end
``` 

### make hands dirty
**分析**: 要小于O(k), 就不能访问所有元素，某些元素没被访问就可以排除了。

从第一队取出第15个人A，第2队取出第25个人B，如果A<B，可以发现包括第一队包括A在内的这15人都可以排除了（想想为什么）。
因此，我们每次从第一组取第k/2个，第二组第k-k/2个，这样一次比较就能排除一半的人，yes!

### coding
于是，try伪码:
```ruby
def kth(k, arrx, arry)
    return [arrx.first, arry.first].min if k==0

    xmid = k/2
    ymid = k-xmid
    if arrx[xmid] <= arry[ymid]
      kth(k-xmid-1, arrx[xmid+1..-1], arry)
    else
      kth(k-ymid-1, arrx, arry[ymid+1..-1])
    end
  end
```

扩充完整：
```ruby
class KthOfTwoSorted
  def safe_kth(k, arrx, arry)
    return [arrx.first,arry.first].compact.min if k==0

    xmid = k/2
    ymid = k-(xmid+1)
    if arrx[xmid] <= arry[ymid]
      safe_kth(k-xmid-1, shift(arrx,xmid+1), arry)
    else
      safe_kth(k-ymid-1, arrx, shift(arry, ymid+1))
    end
  end

  def kth_of_two_sorted(k, arrx, arry)
    (arrx.size+arry.size).tap do |len|
      raise ArgumentError,"k should in range #{0..len}" unless 0<=k && k<len
    end

    arrx,arry = [arrx,arry].sort_by(&:size)
    if arrx.size < k
      arry.shift(k-arrx.size)
      k = arrx.size
    end

    safe_kth(k, arrx, arry)
  end

  private
  def shift(arr, n); arr.shift(n);arr end
end
```
测试代码:
```ruby
require_relative '../kth_of_two_sorted_list'

shared_examples_for "find kth" do
  it "should find kth" do
    # k = n-1
    # ans = (x+y).sort[k]
    expect(result).to eq ans
  end
end

describe KthOfTwoSorted do
  let(:result) {subject.kth_of_two_sorted(n-1,x,y)}
  context "example normal" do
    let(:x) {[1,3,5,7,9]}
    let(:y) {[2,4,6,8,10]}
    let(:n) {8}
    let(:ans) {8}
    it_behaves_like "find kth"
  end
  context "when one is empty" do
    let(:x) {[]}
    let(:y) {(1..10).to_a}
    let(:n) {9}
    let(:ans) {9}
    it_behaves_like "find kth"
  end
  context "when one is too short" do
    let(:x) {[1,2,3]}
    let(:y) {(4..10).to_a}
    let(:n) {9}
    let(:ans) {9}
    it_behaves_like "find kth"
  end
  context "when repeat" do
    let(:x) {(1..100).select(&:odd?) + (101..200).to_a}
    let(:y) {(1..100).select(&:even?) + (101..200).to_a}
    let(:n) {200}
    let(:ans) {150}
    it_behaves_like "find kth"
  end
  context "when out of range" do
    let(:x) {[]}
    let(:y) {x}
    let(:n) {10}
    it "should raise error" do
      expect{result}.to raise_error(/k should in range/)
    end
  end
end

```
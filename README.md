# What could be dynamic in a block(proc) ?

#### Test
```ruby
def laugh
  "main haha"
end
def foo
  "main's foo method"
end
/main_match/.match 'main_match...'
foo = "main's foo"

blk = proc do
  puts foo, @msg, $&, laugh, '-'*10
end

class Bar
  def laugh
    "bar haha"
  end
  def foo
    "bar's foo method"
  end
  def run(&blk)
    /bar_match/.match 'bar_match...'
    foo = "bar's foo variable"
    @msg = "bar's msg"

    puts '='*10 + 'call blk in bar:'
    blk[]

    puts '='*10 + 'instance_eval blk in bar:'
    instance_eval(&blk)

    puts $&
  end
end

@msg = "main's msg"
bar = Bar.new
bar.run(&blk)

puts $&
```

#### Output

```
==========call blk in bar:
main's foo
main's msg
main_match
main haha
----------
==========instance_eval blk in bar:
main's foo
bar's msg
main_match
bar haha
----------
bar_match
main_match
```

### Conclusions:
* token parse order:
    1. as variable from ancestor env, if exist
    2. as variable of current env, if exist
    3. as method of 'self', if exist
* dynamic part:
    * lexical_scope/env chain won't change: variables are bound to lexical_scope_chain forever
    * only 'self' changeable
* so, if we want pass dynamic data to block, we have to introduce them:
    1. as method/message(by change 'self')
    2. as args(`instance_exec` if both)

# 和小于k的最长连续子串

### 问题
已知一个长度为n的数组（允许负数）, 和一个整数k, 求：和小于k的最长连续子串？

例如: 

k=184, A=[431, -15, 639, 342, -14, 565, -924, 635, 167, -70], 

和小于184的最长子串为A[3..6]

### 写个简单测试先

```ruby
require_relative '../longest_subarray_with_sum_less_than_k'

describe LongestSub do
  let(:array) {[431, -15, 639, 342, -14, 565, -924, 635, 167, -70]}
  let(:bound) {184}
  let(:result) {subject.longest(array,bound)}
  let(:ans) {array[3..6]}
  it "should compute the longest subarray whose sum <= bound" do
    expect(result).to eq ans
  end
end
```

### 分析
如果暴力枚举起点和终点，复杂度为O(n^2)。能不能找到一些规律优化呢？


### Make hands dirty

单纯考虑原数组好像找不到规律。

考虑前缀和，此时问题转换为已知pre数组，求pre[j]-pre[i]<=k的距离最大(i,j)对.

由于有负数，pre数组没有递增规律。

第一个元素的右端点，就已经难以确定了，必须从右到左扫描，直到差值<=k，有可能一个都不成功；而且，算好i后，算i＋1时好像还是要扫描所有之后的右端点。

于是考虑对pre排序, 然后可以用“双指针”，不断移动右指针直到>k，并一直保存当前最右下标。这样需要复杂度O(nlogn)排序＋O(n) == O(nlogn)

### Make it better

还有更好的方法吗？有没有什么规律，来排除一些值呢？

可以发现右端点中，如果`j1<j2`而且`pre[j1]>=pre[j2]`，那肯定不会选j1, 因为j2既比j1远，求和时结果又比j1小。所以，可以从右到左扫描一遍，过滤掉不可能的右端点。

而且发现，这样过滤后的右端点在pre上是递增的，就可以用“双指针”求了。

复杂度 = O(n)过滤 + O(n)扫描 ＝ O(n)

代码：
```ruby
class LongestSub
  def longest(arr,bound)
    reset(arr,bound)
    l,r = [(0...size),poss_r].map(&:to_enum)
    loop { update(l,r) }
    arr[@longest_range]
  end

  def update(l, r)
    i,j = [l,r].map(&:peek)
    if i<=j && presum(j,i)<=bound
      @longest_range = [@longest_range, (i..j)].max_by(&:size)
      r.next
    else
      l.next
    end
  end

private
  attr_reader :arr, :bound
  def reset(arr,bound)
    @arr,@bound=[arr,bound]
    @poss_r = @pre  = nil
    @longest_range = (0...0)
  end
  def size; arr.size end
  def pre
    @pre ||= arr.reduce([0]){|res,v| res << res.last+v}
  end
  def presum(j,i=0)
    pre[j+1] - pre[i]
  end
  def poss_r
    @poss_r ||= (0...size).reverse_each.reduce([]) do |res,i|
      res.unshift(i) unless res.first && presum(i) >= presum(res.first)
      res
    end
  end
end
```



# y combinator: 不引用自己也能实现递归？

### 问题
递归函数，比如求阶乘: 
`f = ->(n){ n==0? 1 : n*f[n-1] }`
这里右边引用了f，可以不引用自身实现递归么？

### show me the money
答案如下:
```ruby
# proc[x] === proc.call(x)
y = ->(f){->(x){x[x]}[->(x){f[->(g){x[x][g]}]}]}    
_fact = ->(f){->(n){n==0?1:n*f[n-1]} }
fact = y[_fact]
puts (1..10).map(&fact)
```

### 分析
以上的关键在于神奇y函数，它是啥？

首先，对于任何一个引用自己的递归函数r，我们都能写出一个不引用自己的almost版本函数： 
```
r = (*args) -> {...r...}
almost_r = (f)->(*args)->{...f...}
```

然后会发现: `almost_r(r) === r`

r是almost_r的不动点

而y函数叫做y combinator，它能够对于一个给定函数，求出它的不动点。

因此y(almost_r) == r, 这里y和almost_r都不引用自身。

所以，对于任何一个递归函数r，我们都能把它写成y(almost_r)的形式，一个没有自我引用的形式。（y是已知的，almost_r是从r推导的，也是已知的）

### Y combinator （Y不动点组合子）
y函数是怎么得到的?
```
        r:=real, a:=almost, p:=part
        假设:
            r = (arg)->...r...
            a = (f)->(arg)->...f...
            p = (f)->(arg)->...ff...
            y = (a)->r
            (a(r) == r)
            这里只有r引用了自己，a和p都没有引用自己
        于是:
            p == (f)->a(ff) 
            所以, pp = a(pp) = (arg)-> ...pp... 
            所以，pp == r
            所以, y(a) = r = pp = ((x)->xx)p = ((x)->xx)((f)->a(ff))
            y = (a)->((x)->xx)((f)->a(ff)) = (a)->((x)->xx)((f)->a((g)->(ff)g))

```
大概就是这样吧，哦吼吼吼，请不要太在意细节...

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
  def initialize
    @rules=[]
    yield self if block_given?
  end

  def add_rule(&blk); @rules << blk end

  def report(number)
    reset
    @rules.each do |rule|
      @stopped ? break : instance_exec(number, &rule)
    end
    @result
  end

  private
  def stop_with(word)
    @stopped = true
    @result=word
  end
  def reset; @result = @stopped = nil end
end

def create_fizzbuzz
  Game.new do |r|
    r.add_rule{|number| stop_with('Fizz') if(number.to_s.include?('3')) }
    r.add_rule do |number|
      @result ||= ""
      @result << 'Fizz' if(number%3==0)
      @result << 'Buzz' if(number%5==0)
      @result << 'Whizz' if(number%7==0)
      @result = number if @result.empty?
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
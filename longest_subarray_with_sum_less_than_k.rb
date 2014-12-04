
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
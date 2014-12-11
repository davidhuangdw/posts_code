class Lazy
  def initialize(coll, &trans)
    @coll = coll
    @trans = trans || proc{|c,&b| c.each(&b)}
  end
  def my_lazy; self end

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
  def my_lazy; Lazy.new(self) end
end

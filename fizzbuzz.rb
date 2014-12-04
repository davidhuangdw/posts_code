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
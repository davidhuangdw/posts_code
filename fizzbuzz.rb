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
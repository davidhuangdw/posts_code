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

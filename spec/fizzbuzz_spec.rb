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
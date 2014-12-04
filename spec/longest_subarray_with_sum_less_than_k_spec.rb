require_relative '../longest_subarray_with_sum_less_than_k'

shared_examples_for "longest sub" do
  it "should compute the longest subarray whose sum <= bound" do
    expect(result).to eq ans
  end
end

describe LongestSub do
  let(:array) {[431, -15, 639, 342, -14, 565, -924, 635, 167, -70]}
  let(:bound) {184}
  let(:result) {subject.longest(array,bound)}
  let(:ans) {array[3..6]}
  it_behaves_like 'longest sub'
end
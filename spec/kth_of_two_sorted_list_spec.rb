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

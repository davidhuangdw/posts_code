require_relative '../lazy'

shared_examples_for 'lazy' do
  it "should make lazy enumeration" do
    expect(take_first_three_odd).to eq first_three_odd
  end
end

describe Lazy do
  let(:inf) { (1...Float::INFINITY) }

  let(:lazy_list) {inf.my_lazy.map{|i| i*i}}
  let(:take_first_three_odd) {lazy_list.select(&:odd?).take(3)}
  let(:first_three_odd) {[1,9,25]}

  context 'when infinite list' do
    it_behaves_like 'lazy'
  end

  context 'when drop a few' do
    let(:take_first_three_odd) {lazy_list.reject(&:even?).drop(2).take(3)}
    let(:first_three_odd) {[25,49,81]}
    it_behaves_like 'lazy'
  end

  context 'when drop more than once' do
    let(:take_first_three_odd) {lazy_list.reject(&:even?).drop(1).drop(2).first(3)}
    let(:first_three_odd) {[49,81,121]}
    it_behaves_like 'lazy'
  end

  context 'when have nil' do
    let(:take_first_three_odd) {lazy_list.reject(&:even?).map{nil}.drop(2).first(3)}
    let(:first_three_odd) {[nil,nil,nil]}
    it_behaves_like 'lazy'
  end
end
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
module Stubber
  extend self
  def mystub(method, to:nil, &blk)
    singleton = class << to||self; self end
    singleton.send(:define_method, method, &blk)        # define_method is private for singleton_class: use 'send' to bypass
  end
end